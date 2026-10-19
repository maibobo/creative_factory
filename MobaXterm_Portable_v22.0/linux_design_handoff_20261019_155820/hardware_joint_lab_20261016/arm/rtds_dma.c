/* Small synchronous XDMA AXI-MM transfer tool. No driver or control-BAR writes.
 * Exit: 0 success, 2 arguments, 3 file/device error, 4 DMA error, 5 short DMA.
 * The parent process applies the transfer timeout and never retries a short DMA.
 */
/*
 * 这是用户态同步 XDMA 辅助程序，不是内核驱动。它只打开已有的 xdma*_h2c_0/c2h_0
 * 字符设备，借助 lseek 选择卡内 AXI-MM 地址，再用恰好一次 read/write 提交 DMA。
 * 本程序不访问控制 BAR、不装卸驱动，也不负责队列确认；队列所有权由上层 rtds_lab.py 管理。
 */
#define _POSIX_C_SOURCE 200809L
#define _FILE_OFFSET_BITS 64
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static int number(const char *s, uint64_t *v) {
    /* base=0 同时接受十进制和 0x 十六进制；拒绝负数、空串、溢出和尾随字符。 */
    char *end;
    if (!s[0] || s[0] == '-') return -1;
    errno = 0; *v = strtoull(s, &end, 0);
    return errno || *end ? -1 : 0;
}
static int file_io(int fd, unsigned char *p, size_t n, int write_out) {
    /* 普通文件允许短读/短写，因此循环补齐；这里只处理数据文件，不会重复提交 XDMA。 */
    while (n) {
        ssize_t k = write_out ? write(fd, p, n) : read(fd, p, n);
        if (k < 0 && errno == EINTR) continue;
        if (k <= 0) return -1;
        p += k; n -= (size_t)k;
    }
    return 0;
}
int main(int argc, char **argv) {
    uint64_t addr, size;
    unsigned char *buf = NULL;
    int dev = -1, file = -1, rc = 3, h2c;
    struct timespec t0, t1;
    ssize_t done;
    /* 本实验主动将 DMA 请求限制为 16 Byte 对齐、最大 32 KiB，并确保地址范围可由 off_t 表示。 */
    if (argc != 6 || (strcmp(argv[1], "h2c") && strcmp(argv[1], "c2h")) ||
        number(argv[3], &addr) || number(argv[4], &size) ||
        size == 0 || size > 32768 || (size & 15) || (addr & 15) ||
        addr > INT64_MAX || addr + size > INT64_MAX) {
        fprintf(stderr, "Usage: rtds_dma h2c|c2h DEVICE CARD_ADDR SIZE FILE\n"
                        "Address/size must be 16-byte aligned; size 16..32768.\n");
        return 2;
    }
    h2c = !strcmp(argv[1], "h2c");
    /* 页对齐缓冲区满足常见 XDMA 用户态 DMA 对齐要求；0xa5 也使未覆盖尾部易于识别。 */
    if (posix_memalign((void **)&buf, 4096, (size_t)size)) {
        fprintf(stderr, "aligned allocation failed\n"); return 3;
    }
    memset(buf, 0xa5, (size_t)size);
    if (h2c) {
        /* H2C：提交前必须从输入文件取得完整 size 字节，短文件不会触发 DMA。 */
        file = open(argv[5], O_RDONLY);
        if (file < 0 || file_io(file, buf, (size_t)size, 0)) {
            fprintf(stderr, "input file missing/short: %s\n", strerror(errno)); goto cleanup;
        }
        close(file); file = -1;
    }
    dev = open(argv[2], h2c ? O_WRONLY : O_RDONLY);
    if (dev < 0) { perror("open XDMA device"); goto cleanup; }
    if (lseek(dev, (off_t)addr, SEEK_SET) != (off_t)addr) { perror("card address seek"); goto cleanup; }
    /* 对 XDMA 字符设备 lseek 设置的是卡内地址，不是主机数据文件偏移。 */
    clock_gettime(CLOCK_MONOTONIC, &t0);
    /* Exactly one DMA submission. Do not loop or retry after a partial/error return. */
    /* DMA 返回错误或短传输时，硬件完成状态可能不确定；必须原样上报，不能循环补传。 */
    done = h2c ? write(dev, buf, (size_t)size) : read(dev, buf, (size_t)size);
    int transfer_errno = errno;
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double elapsed = (double)(t1.tv_sec-t0.tv_sec) + (t1.tv_nsec-t0.tv_nsec)/1e9;
    printf("{\"direction\":\"%s\",\"card_address\":%" PRIu64 ",\"requested\":%" PRIu64
           ",\"completed\":%zd,\"elapsed_seconds\":%.9f,\"errno\":%d}\n",
           argv[1], addr, size, done, elapsed, done < 0 ? transfer_errno : 0);
    fflush(stdout);
    /* JSON 同时报告请求数与完成数，供 Python 决定是否允许后续 ACK。 */
    if (done < 0) { errno = transfer_errno; perror("DMA"); rc = 4; goto cleanup; }
    if ((uint64_t)done != size) { fprintf(stderr, "short DMA; no retry performed\n"); rc = 5; goto cleanup; }
    if (!h2c) {
        /* C2H 成功后才创建结果文件；O_EXCL 防止覆盖同名历史证据，fsync 保证数据已提交到存储层。 */
        file = open(argv[5], O_WRONLY | O_CREAT | O_EXCL, 0600);
        if (file < 0 || file_io(file, buf, (size_t)size, 1)) { perror("write result file"); goto cleanup; }
        if (fsync(file)) { perror("sync result file"); goto cleanup; }
    }
    rc = 0;
cleanup:
    /* 所有出口统一释放描述符和 DMA 缓冲区；rc 保留具体失败类别。 */
    if (file >= 0) close(file);
    if (dev >= 0) close(dev);
    free(buf);
    return rc;
}
