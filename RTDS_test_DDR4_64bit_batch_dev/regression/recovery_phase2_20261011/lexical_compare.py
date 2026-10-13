from pathlib import Path
import re,json,difflib,sys
O=Path(__file__).parent
TOKEN=re.compile(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/|(?:\d+)?\x27[sS]?[bBoOdDhH][0-9a-fA-FxXzZ?_]+|[a-zA-Z_$][\w$]*|\d+(?:\.\d+)?|===|!==|>>>|<<<|<<|>>|<=|>=|==|!=|&&|\|\||\*\*|::|[^\s]',re.S)
def tokens(s):return [m.group() for m in TOKEN.finditer(s) if not m.group().startswith(('//','/*'))]
def normalized_tokens(s):
    # Canonicalize standalone net/register/localparam declarations: a,b -> a; b;.
    s=re.sub(r'//[^\n]*|/\*.*?\*/',lambda m:re.sub(r'[^\n]',' ',m[0]),s,flags=re.S)
    pattern=re.compile(r'(?m)^([ \t]*(?:wire|reg|logic|localparam)\b\s*(?:(?:signed|integer|int|real)\s+)?(?:\[[^]]+\]\s*)?)([^;]+);')
    def expand(m):
        depth=0;start=0;parts=[]
        for i,c in enumerate(m[2]):
            if c in '({[':depth+=1
            elif c in ')}]':depth-=1
            elif c==',' and depth==0:parts.append(m[2][start:i]);start=i+1
        parts.append(m[2][start:]);return '\n'.join(m[1]+x.strip()+';' for x in parts)
    return tokens(pattern.sub(expand,s))
if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    old=O/'remote/evidence/local_wave_sessions/recovery_and_1g_20261012/ready_recovery/sources'
    for rel in ['rtl/ddr4/rtds_ddr4_backend.sv','RTDS_test_DDR4_64bit.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v']:
        a=tokens((old/rel).read_text('utf-8-sig'));b=tokens((O/'before'/rel).read_text('utf-8-sig'))
        print(rel,'LEXICAL_EQUAL',a==b,'tokens',len(a),len(b));print(''.join(list(difflib.unified_diff(a,b))[:70]))
        print('NORMALIZED_DECLARATIONS_EQUAL', normalized_tokens((old/rel).read_text('utf-8-sig'))==normalized_tokens((O/'before'/rel).read_text('utf-8-sig')))
