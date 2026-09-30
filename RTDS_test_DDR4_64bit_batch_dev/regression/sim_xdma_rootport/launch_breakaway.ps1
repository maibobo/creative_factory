param(
    [string]$CommandLine = "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\project\RTDS\rtds_rootport_task.ps1",
    [string]$WorkingDirectory = "C:\project\RTDS"
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：在远端创建脱离 sshd Job Object 的回归工作器，SSH 断开后仍继续运行。
# 输入：完整 CommandLine 和 WorkingDirectory。
# 输出：BREAKAWAY_PROCESS_PID；不直接运行 Vivado，也不判断测试 PASS。
# 逻辑阶段：校验目录/命令 → 定义 Win32 启动器 → CreateProcessW → 返回 PID。
# 失败定位：创建失败看 Win32Exception；PID 有但无日志查传入命令/工作目录；
# PID 随 SSH 消失说明 CREATE_BREAKAWAY_FROM_JOB 未生效。
# =============================================================================

# ---------- 语义段 1：脱离 Windows sshd 作业对象 ----------
# OpenSSH 会在会话关闭时回收普通 Start-Process 子进程。这里直接调用
# CreateProcessW，并请求 CREATE_BREAKAWAY_FROM_JOB；成功后子进程由 Windows
# 独立托管，SSH 仅用于启动和查询，不再决定仿真寿命。
$source = @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class RtdsBreakawayLauncher
{
    [StructLayout(LayoutKind.Sequential)]
    private struct STARTUPINFO
    {
        public int cb;
        public IntPtr lpReserved;
        public IntPtr lpDesktop;
        public IntPtr lpTitle;
        public int dwX;
        public int dwY;
        public int dwXSize;
        public int dwYSize;
        public int dwXCountChars;
        public int dwYCountChars;
        public int dwFillAttribute;
        public int dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROCESS_INFORMATION
    {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CreateProcessW(
        string applicationName,
        StringBuilder commandLine,
        IntPtr processAttributes,
        IntPtr threadAttributes,
        bool inheritHandles,
        uint creationFlags,
        IntPtr environment,
        string currentDirectory,
        ref STARTUPINFO startupInfo,
        out PROCESS_INFORMATION processInformation);

    [DllImport("kernel32.dll")]
    private static extern bool CloseHandle(IntPtr handle);

    public static int Launch(string commandLine, string workingDirectory)
    {
        const uint CREATE_NEW_PROCESS_GROUP = 0x00000200;
        const uint CREATE_BREAKAWAY_FROM_JOB = 0x01000000;
        const uint CREATE_NO_WINDOW = 0x08000000;

        STARTUPINFO startupInfo = new STARTUPINFO();
        startupInfo.cb = Marshal.SizeOf(typeof(STARTUPINFO));
        PROCESS_INFORMATION processInformation;
        StringBuilder mutableCommandLine = new StringBuilder(commandLine);

        bool created = CreateProcessW(
            null,
            mutableCommandLine,
            IntPtr.Zero,
            IntPtr.Zero,
            false,
            CREATE_NEW_PROCESS_GROUP | CREATE_BREAKAWAY_FROM_JOB | CREATE_NO_WINDOW,
            IntPtr.Zero,
            workingDirectory,
            ref startupInfo,
            out processInformation);

        if (!created)
            throw new Win32Exception(Marshal.GetLastWin32Error());

        int processId = processInformation.dwProcessId;
        CloseHandle(processInformation.hThread);
        CloseHandle(processInformation.hProcess);
        return processId;
    }
}
'@

if (-not ("RtdsBreakawayLauncher" -as [type])) {
    Add-Type -TypeDefinition $source -Language CSharp
}

$processId = [RtdsBreakawayLauncher]::Launch($CommandLine, $WorkingDirectory)
"BREAKAWAY_PROCESS_PID=$processId"
