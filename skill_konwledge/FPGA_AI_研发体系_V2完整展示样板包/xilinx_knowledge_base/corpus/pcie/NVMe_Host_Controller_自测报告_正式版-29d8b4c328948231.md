# NVMe_Host_Controller_自测报告_正式版

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_Host_Controller_自测报告_正式版.docx`
- SHA-256: `29d8b4c3289482315e9f5dc4074fa3e5d9fcc60c22f67ac4a57e45ed19fb54d5`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\NVMe_Host_Controller_自测报告_正式版.docx

# NVMe Host Controller 自测报告

## 1. 文档信息

| 项目 | 内容 |

| 版本 | NOPHAE V4.5 |

| FPGA | XCKU040 |

| CPU | MicroBlaze |

| PCIe | Gen3 x4 |

| SSD | Samsung 980 PRO 1TB |

| NVMe | 1.3 |


## 2. 测试系统设计框图

由MicroBlaze发送指令，NVMe IP接受指令，处理完成后，Micro读取相应寄存器

## 3. 测试项、测试方法及结果

### PCIe初始化

测试方法：完成PCIe Link Training，读取BAR、Link Speed、Max Payload等配置。

测试结果：PASS

### NVMe初始化

测试方法：完成Identify Controller、Identify Namespace、Admin Queue、IO Queue创建。

测试结果：PASS

### DMA功能

测试方法：执行DDR→SSD、SSD→DDR传输，并进行数据校验。

测试结果：PASS

### AXI读写

测试方法：通过AXI接口读写寄存器并校验数据。

测试结果：PASS

### 数据一致性

测试方法：16MB指定地址读写后比较数据一致性。

测试结果：PASS

## 顺序读写性能（MiB/s）

使用DMA接口每次提交1GB数据读写指令，在DDR的起始位置，和SSD的起始lba之间做读写，1GiB以上的数据传输执行多次上述操作，记录最终时间，设置2队列8深度，MDTS为7(SSD给出的固定值)，单次SQE大小为512KB，IP会将DMA指令拆分成多条SQE，通过修改传入IP的MDTS,可以调整单次SQE可传输的大小

| 数据量(GiB) | 块大小(KB) | 顺序写(MiB/s) | 顺序读(MiB/s) |

| 1 | 4 | 2994 | 2701 |

| 1 | 512 | 3313 | 3368 |

| 2 | 512 | 3313 | 3368 |

| 4 | 512 | 3316 | 3371 |

| 8 | 512 | 3311 | 3371 |

| 16 | 512 | 3312 | 3368 |

| 32 | 512 | 3313 | 3369 |

| 64 | 512 | 3313 | 3368 |


## 随机IOPS测试

随机IOPS测试，在IP内部集成了一个用于测试随机IOPS的Bist模块，调用这个模块记录1秒内完成的CMD，并记录最后的1024条指令的Latency，在任务完成后MicroBlaze读取总的CMD数，和1024条Latency，并对Latency执行冒泡排序，去除极值，计算平均值，该模块暂不支持调整测试指令块大小，目前为4KB.

| 配置 | 块大小 | 方向 | IOPS | Avg(us) | P95(us) | P99(us) |

| Q1D2 | 4KB | Write | 118326 | 16 | 17 | 17 |

| Q1D2 | 4KB | Read | 45803 | 43 | 54 | 54 |

| Q8D8 | 4KB | Write | 764273 | 75 | 86 | 86 |

| Q8D8 | 4KB | Read | 752148 | 123 | 197 | 252 |


## 5. 稳定性测试

连续完成64GiB顺序读写测试，带宽保持稳定，无DMA错误、无PCIe Link异常、无NVMe Command Timeout、无数据校验错误。

## 6. 测试结论

NVMe Host Controller功能验证全部通过。顺序写带宽达到3313 MiB/s，顺序读带宽达到3368 MiB/s；随机写IOPS达到764,273，随机读IOPS达到752,148。系统运行稳定，可作为当前版本性能基线。
