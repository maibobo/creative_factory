# 本地命令记录入口：写入命令、完整输出、退出码，并同步远程调试MD。
# 用法：python scripts/record_debug_command.py ssh vivado-srv "远程命令"
# 私钥、密码、令牌等敏感内容不得作为命令文本传入。
import subprocess,sys,datetime,pathlib
P=pathlib.Path(__file__).resolve().parents[1]
doc=P/"docs/远程V2.01_调试过程与命令记录.md"
args=sys.argv[1:]
stamp=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
with doc.open("a",encoding="utf-8") as f:f.write("\n### "+stamp+"\n\n```text\n"+subprocess.list2cmdline(args)+"\n```\n")
r=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
try:s=r.stdout.decode("utf-8")
except UnicodeDecodeError:s=r.stdout.decode("gb18030",errors="replace")
with doc.open("a",encoding="utf-8") as f:f.write("\n退出码："+str(r.returncode)+"\n\n```text\n"+s+"\n```\n")
print(s)
subprocess.run(["scp",str(doc),"vivado-srv:C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/docs/远程V2.01_调试过程与命令记录.md"])
sys.exit(r.returncode)
