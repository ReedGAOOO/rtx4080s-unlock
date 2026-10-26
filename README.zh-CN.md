# rtx4080s-unlock — Windows · RTX 4080 SUPER · 32GB 改装卡

**面向 Windows 下 RTX 4080 SUPER 32GB 显存改装卡（`10de:2702`）的 Tensor Core 解锁研究。**

[English](README.md) | **简体中文**

## 实测结果：4080 SUPER 对比 4090 与 5090

**2026-10-26 · 实际测量 · 中位数 TFLOPS。** 4080 SUPER 与 4090 已解锁；5090 为原厂状态。

### 指令吞吐

| 测试（输入 / 累加） | 4080 SUPER 32GB · 解锁 | 4090 24GB · 解锁 | 5090 32GB · 原厂 |
|---|---:|---:|---:|
| FP16 / FP16 | 204.80 | 327.50 | 449.10 |
| FP16 / FP32 | 205.00 | 327.30 | 224.80 |
| BF16 / FP32 | 204.90 | 327.00 | 224.50 |
| FP8 E4M3 | 408.40 | 651.90 | 449.20 |
| FP32 FFMA | 50.50 | 78.00 | 109.10 |

### cuBLAS 矩阵乘法 — 8192 × 8192 × 8192

| 测试（输入 / 累加） | 4080 SUPER 32GB · 解锁 | 4090 24GB · 解锁 | 5090 32GB · 原厂 |
|---|---:|---:|---:|
| FP16/FP32 GEMM 8192³ | 190.49 | 195.72 | 236.12 |
| BF16/FP32 GEMM 8192³ | 190.15 | 205.05 | 234.49 |

**测试条件：** 4080 SUPER：Windows/WSL2、320W 上限、驱动 617.42；4090：Linux、550W 上限、驱动 595.99.02；5090：Linux、575W 上限、驱动 570.211.01。两张 Ada 卡使用相同二进制与 cuBLAS 12.4.5.8；5090 使用原生 `sm_120`、CUDA 12.8.93 与 cuBLAS 12.8.4.1。工作负载与启动参数一致，但软件栈不同。

三卡各通过 169,869,312 个 FP16/BF16 GEMM 输出校验及六组种子用例，均零误差。FP8 指令吞吐单独报告；其长累加校验问题见[已知问题](docs/KNOWN-ISSUES.md)。

在这组 8192³ 矩阵中，4080 SUPER 的 FP16/BF16 GEMM 吞吐约为解锁 4090 的 **97% / 93%**，而 FP32 累加 Tensor 指令吞吐约为其 **63%**。结果对应本套工作负载；三卡的完整测试条件见下方文档。[完整表格、样本与方法](docs/COMPARISON.md)。

## 项目贡献

聚焦 **Windows + RTX 4080 SUPER + 32GB 显存改装**，实现板卡专用 UEFI 适配、开机自动解锁、执行结果归档与登录检查，并公开源码、测试和迁移方法。这是针对该细分配置的先行探索；发布准备时未检索到同组合的公开案例，首例归属仍待社区补充。

- **Windows 启动链：** UEFI 执行 → PCIe FLR → 恢复显示 → 进入 Windows。
- **自动启动：** 新日志与 CUDA 检查通过后续约 BootNext，失败时保留记录。
- **实机配置：** `10de:2702` / `10de:18cc`、AD103 A1、32GB 改装、Windows 11 Pro、驱动 617.42、VBIOS `95.03.44.40.74`。
- **验证：** 113 个 CPU 模拟场景、37 项后台策略测试、实机记录及三卡性能对比。

## 开始使用

当前源码版本为 **0.6.2-public.1**，来自已实测的本地部署 **0.6.2**。公开配置采用占位身份信息，默认构建关闭硬件执行；按照迁移文档生成目标机器配置后再部署。固件与 ROM 由使用者按上游许可本地准备。

1. [编译与测试](docs/BUILD.md)
2. [板卡适配与迁移](docs/PORTING.md)
3. [自动启动、通知与恢复](docs/BOOT-LIFECYCLE.md)
4. [三卡完整测试](docs/COMPARISON.md) · [历史验证记录](docs/VALIDATION.md) · [已知问题](docs/KNOWN-ISSUES.md)

## 目录

| 路径 | 内容 |
|---|---|
| `source/unlock/` | UEFI 应用、GPU 执行流程、硬件配置与测试 |
| `source/firmware-tools/` | 上游固件准备工具和固定版本元数据 |
| `host/`、`notifier/` | Windows 自动续约、健康检查与登录通知 |
| `benchmarks/`、`evidence/` | 微基准源码、实测结果和样本 |
| `docs/` | 编译、迁移、启动与验证文档 |

## 上游与许可

基于 [TOTORONG/AD103_win_unlocker](https://huggingface.co/TOTORONG/AD103_win_unlocker) 与 [Zagitta/gpu-unlock](https://github.com/Zagitta/gpu-unlock) 的解锁研究；本项目贡献是上述 Windows 板卡配置的适配与部署流程。完整署名见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

**供学习与研究使用。** 采用 [GPL-2.0](LICENSE)，保留第三方许可；用途说明不增加 GPL 使用限制。[免责声明](DISCLAIMER.zh-CN.md)集中说明硬件风险和无担保条款。

欢迎提交适配记录、同卡前后对比、问题复现与代码改进，见 [CONTRIBUTING.md](CONTRIBUTING.md)。
