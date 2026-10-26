from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math
import textwrap

INK = '#202a33'
LINE = '#5b6670'
FILL = '#f0f2f4'
WHITE = '#ffffff'

def get_font(size, bold=False):
    paths = [
        r'C:\Windows\Fonts\arialbd.ttf' if bold else r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\segoeuib.ttf' if bold else r'C:\Windows\Fonts\segoeui.ttf'
    ]
    for path in paths:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()

def center_text(draw, xy, text, font, fill=INK, anchor='mm'):
    draw.text(xy, text, fill=fill, font=font, anchor=anchor, align='center')

def oval(draw, cx, cy, text, w=220, h=78, size=27, bold=False):
    draw.ellipse((cx-w/2, cy-h/2, cx+w/2, cy+h/2), fill=WHITE, outline=LINE, width=4)
    face=get_font(size,bold)
    center_text(draw, (cx, cy), text, face)
    if 'PK' in text:
        tw=draw.textlength(text,font=face)
        draw.line((cx-tw/2,cy+size*.34,cx+tw/2,cy+size*.34),fill=INK,width=2)

def entity(draw, xy, title, size=32):
    draw.rectangle(xy, fill=FILL, outline=LINE, width=5)
    center_text(draw, ((xy[0]+xy[2])/2, (xy[1]+xy[3])/2), title, get_font(size, True))

def diamond(draw, cx, cy, label, w=210, h=110, size=25):
    points = [(cx,cy-h/2),(cx+w/2,cy),(cx,cy+h/2),(cx-w/2,cy)]
    draw.polygon(points, fill=WHITE, outline=LINE)
    draw.line(points+[points[0]], fill=LINE, width=4, joint='curve')
    center_text(draw, (cx,cy), label, get_font(size))

def connector(draw, points, width=4):
    draw.line(points, fill=LINE, width=width, joint='curve')

def arrow(draw, points, width=4, head=16):
    draw.line(points, fill=LINE, width=width, joint='curve')
    x1,y1=points[-2]; x2,y2=points[-1]
    angle=math.atan2(y2-y1,x2-x1)
    left=(x2-head*math.cos(angle-.48),y2-head*math.sin(angle-.48))
    right=(x2-head*math.cos(angle+.48),y2-head*math.sin(angle+.48))
    draw.polygon([(x2,y2),left,right],fill=LINE)

def make_chen_er(out_dir):
    w,h=3000,1535
    img=Image.new('RGB',(w,h),WHITE); d=ImageDraw.Draw(img)
    center_text(d,(w/2,55),'DIGITAL BANKING SYSTEM — CHEN ER DIAGRAM',get_font(50,True))
    # Main one-to-many relations and the one-to-one Auth/profile relation.
    connector(d,[(480,735),(615,735)]); connector(d,[(785,735),(930,735)])
    connector(d,[(1450,735),(1650,735)]); connector(d,[(1840,735),(1970,735)])
    connector(d,[(2260,380),(2260,535)]); connector(d,[(2260,635),(2260,650)])
    connector(d,[(1050,820),(850,965)]); connector(d,[(850,1055),(685,1190)])
    connector(d,[(1320,820),(1510,963)]); connector(d,[(1510,1057),(1530,1190)])
    connector(d,[(2200,820),(2200,965)]); connector(d,[(2200,1055),(2500,1190)])
    # Chen relationship diamonds.
    diamond(d,700,735,'has',190,100,31)
    diamond(d,1745,735,'owns',210,104,31)
    diamond(d,2260,585,'serves',200,100,30)
    diamond(d,850,1010,'saves',190,100,30)
    diamond(d,1510,1010,'initiates',225,104,29)
    diamond(d,2200,1010,'records',225,104,29)
    # Cardinality labels.
    for xy,t in [((535,700),'1'),((875,700),'1'),((1515,700),'1'),((1905,700),'N'),
                 ((2220,465),'1'),((2300,625),'N'),((985,900),'1'),((760,1100),'N'),
                 ((1410,900),'1'),((1570,1100),'N'),((2200,900),'1'),((2370,1100),'N')]:
        center_text(d,xy,t,get_font(28))
    # Entity boxes.
    entity(d,(100,650,480,820),'AUTH.USERS',36)
    entity(d,(930,650,1450,820),'PROFILES',38)
    entity(d,(1970,650,2550,820),'ACCOUNTS',38)
    entity(d,(1970,210,2550,380),'BRANCHES',38)
    entity(d,(400,1190,970,1360),'BENEFICIARIES',32)
    entity(d,(1240,1190,1820,1360),'TRANSACTIONS',34)
    entity(d,(2150,1190,2850,1360),'RECOVERY DEMO EVENTS',29)
    # Compact attribute ovals. Primary-key attributes are underlined.
    for cx,label in [(175,'id (PK)'),(390,'email')]:
        oval(d,cx,560,label,190,78,27); connector(d,[(cx,599),(cx,650)])
    for cx,label in [(980,'user_id PK/FK'),(1210,'full_name'),(1435,'role / branch FK')]:
        oval(d,cx,555,label,215,78,26); connector(d,[(cx,594),(cx,650)])
    for cx,label in [(2020,'branch_id PK'),(2260,'branch_code UQ'),(2500,'branch_name')]:
        oval(d,cx,125,label,230,78,26); connector(d,[(cx,164),(cx,210)])
    for cx,label in [(2005,'account_id PK'),(2190,'user_id FK'),(2375,'account_type'),(2560,'balance / status')]:
        oval(d,cx,900,label,195,78,24); connector(d,[(cx,861),(cx,820)])
    for cx,label in [(450,'beneficiary_id PK'),(625,'user_id FK'),(800,'nickname / bank')]:
        oval(d,cx,1455,label,180,78,23); connector(d,[(cx,1416),(cx,1360)])
    for cx,label in [(1280,'transaction_id PK'),(1465,'amount / type'),(1650,'status / initiator')]:
        oval(d,cx,1455,label,180,78,23); connector(d,[(cx,1416),(cx,1360)])
    for cx,label in [(2180,'event_id PK'),(2400,'user_id / account FK'),(2630,'amount / status')]:
        oval(d,cx,1455,label,200,78,23); connector(d,[(cx,1416),(cx,1360)])
    img.save(out_dir/'digital_banking_chen_er.png',dpi=(180,180))

def wrap_field(text, max_chars=22):
    return textwrap.wrap(text,width=max_chars,break_long_words=True,break_on_hyphens=False) or ['']

def table_box(draw, x, y, w, title, fields, font_size=24):
    per_row=4
    groups=[fields[i:i+per_row] for i in range(0,len(fields),per_row)]
    header_h=50; row_h=90
    total_h=header_h+row_h*len(groups)
    draw.rectangle((x,y,x+w,y+total_h),fill=WHITE,outline=LINE,width=5)
    draw.rectangle((x,y,x+w,y+header_h),fill=FILL,outline=LINE,width=5)
    center_text(draw,(x+18,y+header_h/2),title.upper(),get_font(29,True),anchor='lm')
    cell_w=w/per_row
    for row_idx,group in enumerate(groups):
        y1=y+header_h+row_idx*row_h
        y2=y1+row_h
        draw.line((x,y2,x+w,y2),fill=LINE,width=3)
        for col in range(per_row+1):
            xx=x+col*cell_w
            draw.line((xx,y1,xx,y2),fill=LINE,width=3)
        for col,field in enumerate(group):
            lines=wrap_field(field,22)
            line_h=font_size+5
            start_y=(y1+y2)/2-(len(lines)-1)*line_h/2
            for li,line in enumerate(lines):
                face=get_font(font_size)
                cy=start_y+li*line_h
                center_text(draw,(x+col*cell_w+cell_w/2,cy),line,face)
                if '(PK' in field:
                    tw=draw.textlength(line,font=face)
                    cx=x+col*cell_w+cell_w/2
                    draw.line((cx-tw/2,cy+font_size*.36,cx+tw/2,cy+font_size*.36),fill=INK,width=2)
    return (x,y,x+w,y+total_h)

def make_relational_schema(out_dir):
    w,h=1600,1960
    img=Image.new('RGB',(w,h),WHITE); d=ImageDraw.Draw(img)
    center_text(d,(w/2,42),'DIGITAL BANKING SYSTEM — RELATIONAL SCHEMA',get_font(36,True))
    tw=1440
    tables=[
        ('auth.users (Supabase managed)',80,100,['id UUID (PK)','email TEXT','created_at TIMESTAMPTZ']),
        ('profiles',80,255,['user_id UUID (PK, FK → auth.users.id)','full_name TEXT','email TEXT','phone TEXT','role user_role','branch_id UUID (FK → branches.branch_id)','created_at TIMESTAMPTZ']),
        ('branches',80,500,['branch_id UUID (PK)','branch_code TEXT (UQ)','branch_name TEXT','address TEXT','city TEXT','created_at TIMESTAMPTZ']),
        ('accounts',80,745,['account_id UUID (PK)','account_number TEXT (UQ)','user_id UUID (FK → profiles.user_id)','branch_id UUID (FK → branches.branch_id)','account_type account_type','balance NUMERIC','status account_status','opened_on DATE','created_at TIMESTAMPTZ']),
        ('beneficiaries',80,1080,['beneficiary_id UUID (PK)','user_id UUID (FK → profiles.user_id)','nickname TEXT','beneficiary_name TEXT','beneficiary_account_number TEXT','bank_name TEXT','ifsc_code TEXT','created_at TIMESTAMPTZ']),
        ('transactions',80,1325,['transaction_id UUID (PK)','from_account_id UUID (FK → accounts.account_id)','to_account_id UUID (FK → accounts.account_id)','amount NUMERIC','transaction_type transaction_type','status transaction_status','description TEXT','initiated_by UUID (FK → profiles.user_id)','created_at TIMESTAMPTZ']),
        ('recovery_demo_events',80,1660,['event_id UUID (PK)','user_id UUID (FK → profiles.user_id)','from_account_id UUID (FK → accounts.account_id)','to_account_masked TEXT','amount NUMERIC','status TEXT','detail TEXT','created_at TIMESTAMPTZ'])
    ]
    # Vertically stacked table cards keep the schema compact and easy to scan.
    # FK fields identify their referenced table and key inline.
    for title,x,y,fields in tables: table_box(d,x,y,tw,title,fields,24)
    img.save(out_dir/'digital_banking_relational_schema.png',dpi=(180,180))

def generate_schema_diagrams(out_dir):
    out_dir=Path(out_dir); out_dir.mkdir(parents=True,exist_ok=True)
    make_chen_er(out_dir)
    make_relational_schema(out_dir)
