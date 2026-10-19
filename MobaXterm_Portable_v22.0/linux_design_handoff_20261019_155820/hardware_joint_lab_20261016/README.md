# RTDS ARM—FPGA 板内联调实验包 V1.0

2026-10-16。已自动部署到ARM：/root/rtds_joint_lab_20261016。

先读docs/RTDS_ARM_FPGA板内联调实验手册_20261016.md，逐项实测见docs/RTDS_部署与实测记录_20261016.md。同名Word版只做DOCX结构校验，没有渲染。现场简表见docs/RTDS_板内联调现场操作卡_20261016.md。

当前已通过两种入口的env、regs、config和16Byte DDR DMA闭环；单块/多块VIO及ILA现场验证因JTAG target不可枚举而待测。已有旧版资料及ARM更新前版本保存在backups。

ARM最短使用命令：

~~~sh
cd /root/rtds_joint_lab_20261016
python3 arm/rtds_lab.py env
python3 arm/rtds_lab.py regs
python3 arm/rtds_lab.py config --exclusive
python3 arm/rtds_lab.py ddr --exclusive --no-jtag
~~~

所有写入/DMA实验前暂停其他业务。VIO上行操作、Trigger/VIO先后顺序、批处理选项、故障取证见完整手册。当前VIO模式不验证真实Aurora RX。

目录：arm为板端源码及回收的aarch64二进制；pc为部署/验证/文档工具；vivado为Tcl；tests为离线检查；validation为原始实测和判据；docs为说明；package_manifest.json记录发布文件哈希。

PC部署工具依赖Paramiko，放在本机用户缓存，ARM Python仅用标准库。需要在其他PC安装时，用该PC的Python执行python -m pip install --target "%USERPROFILE%/.cache/rtds-lab-hostdeps" paramiko；先配置并验证SSH别名vivado-srv及板端主机密钥，再运行pc/lab_remote.py。ARM密码交互输入，不保存。
