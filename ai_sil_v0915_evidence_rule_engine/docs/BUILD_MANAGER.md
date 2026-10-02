# RT-Thread Studio Build 说明

## 设计原则

Workbench 不自己实现编译器，也不要求用户为了本工具额外配置 SCons。

完整链路：

```text
自然语言需求
  -> Generate MSH Test
  -> applications/ai_generated_test.c
  -> RT-Thread Studio Build
  -> Debug/rtthread.elf 或 Debug/rtthread.bin
  -> QEMU
```

## 自动构建

`Studio Build` 会尝试定位 RT-Thread Studio 的 `studio.exe` 或 `eclipsec.exe`，使用 Eclipse CDT 的 headless build 模式在临时 workspace 中导入并构建当前工程。

使用临时 workspace 的原因是避免和用户已经打开的正常 RT-Thread Studio workspace 发生锁冲突。

同时会尝试把 Studio 自带的 `make.exe` 与 `arm-none-eabi-gcc.exe` 所在目录加入子进程 PATH。

## 自动构建失败时

不同 RT-Thread Studio 版本的 headless build 环境差异较大，因此保留稳定 fallback：

1. CodeGen 已经完成，文件就在 `applications/`
2. 在正常 RT-Thread Studio 中 Refresh（如需要）并 Build 一次
3. 回 Workbench 点击 `Detect Firmware`
4. Workbench 检查 Firmware 是否比生成测试代码更新
5. 确认后即可 QEMU 运行

## main.c

Workbench 不修改 `main.c`。

MSH 命令通过：

```c
MSH_CMD_EXPORT(...)
```

注册；SIL Runtime 初始化通过：

```c
INIT_APP_EXPORT(...)
```

自动执行。
