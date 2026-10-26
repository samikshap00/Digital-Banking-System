from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'report'
ASSET = OUT / 'assets'
ASSET.mkdir(exist_ok=True)

def font(size=12, bold=False, italic=False):
    f = ImageFont.load_default()
    return f

def box(draw, xy, text, fill='#EAF2FF', outline='#2164E8'):
    draw.rounded_rectangle(xy, radius=16, fill=fill, outline=outline, width=3)
    x1,y1,x2,y2=xy
    draw.text(((x1+x2)//2, (y1+y2)//2), text, anchor='mm', fill='#132238', font=font())

def make_er():
    img=Image.new('RGB',(1200,720),'white'); d=ImageDraw.Draw(img)
    box(d,(40,70,270,260),'PROFILES'); box(d,(480,70,760,260),'ACCOUNTS'); box(d,(900,70,1160,260),'BRANCHES')
    box(d,(260,430,570,650),'TRANSACTIONS', '#F2F8F4','#16805A'); box(d,(720,430,1060,650),'BENEFICIARIES','#FFF7E6','#C67C00')
    for a,b in [((270,165),(480,165)),((760,165),(900,165)),((360,260),(430,430)),((650,260),(840,430))]: d.line((a,b),fill='#64748B',width=4)
    d.text((600,25),'Entity Relationship Diagram',anchor='mm',fill='#132238',font=font())
    img.save(ASSET/'er_diagram.png')

def make_arch():
    img=Image.new('RGB',(1200,650),'white'); d=ImageDraw.Draw(img)
    box(d,(60,240,300,400),'Customer / Staff'); box(d,(480,240,720,400),'Browser UI','#F2F8F4','#16805A'); box(d,(900,240,1140,400),'Supabase','#FFF7E6','#C67C00')
    for x1,x2 in [(300,480),(720,900)]: d.line((x1,320,x2,320),fill='#2164E8',width=5); d.polygon([(x2,320),(x2-18,310),(x2-18,330)],fill='#2164E8')
    d.text((600,90),'System Architecture and Access Flow',anchor='mm',fill='#132238',font=font())
    for x,text in [(180,'Auth'),(600,'Fetch / RPC'),(1020,'PostgreSQL + RLS')]: d.text((x,500),text,anchor='mm',fill='#64748B',font=font())
    img.save(ASSET/'architecture.png')

def set_cell_shading(cell, fill):
    tcPr = cell._tc.get_or_add_tcPr(); shd = OxmlElement('w:shd'); shd.set(qn('w:fill'), fill); tcPr.append(shd)

def set_cell_border(cell, color='D9D9D9'):
    tc = cell._tc; tcPr = tc.get_or_add_tcPr(); borders = tcPr.first_child_found_in('w:tcBorders')
    if borders is None: borders=OxmlElement('w:tcBorders'); tcPr.append(borders)
    for edge in ('top','left','bottom','right','insideH','insideV'):
        tag='w:'+edge; el=borders.find(qn(tag))
        if el is None: el=OxmlElement(tag); borders.append(el)
        el.set(qn('w:val'),'single'); el.set(qn('w:sz'),'4'); el.set(qn('w:color'),color)

def add_table(doc, headers, rows):
    t=doc.add_table(rows=1, cols=len(headers)); t.alignment=WD_TABLE_ALIGNMENT.CENTER; t.style='Table Grid'
    for i,h in enumerate(headers):
        c=t.rows[0].cells[i]; c.text=h; set_cell_shading(c,'1F4E79'); set_cell_border(c); c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
        for r in c.paragraphs[0].runs: r.font.color.rgb=RGBColor(255,255,255); r.font.bold=True
    for ri,row in enumerate(rows):
        cells=t.add_row().cells
        for i,val in enumerate(row):
            cells[i].text=str(val); set_cell_border(cells[i]); cells[i].vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            if ri%2==1: set_cell_shading(cells[i],'F3F6FA')
    return t

def p(doc, text='', bold=False, italic=False, align=None):
    para=doc.add_paragraph(); para.paragraph_format.space_after=Pt(6); para.paragraph_format.line_spacing=1.5
    if align is not None: para.alignment=align
    run=para.add_run(text); run.bold=bold; run.italic=italic; run.font.name='Times New Roman'; run.font.size=Pt(12); run.font.color.rgb=RGBColor(0,0,0)
    return para

def heading(doc, text, level=1):
    para=doc.add_paragraph(style=f'Heading {level}'); para.paragraph_format.space_before=Pt(12); para.paragraph_format.space_after=Pt(6)
    run=para.add_run(text); run.font.name='Times New Roman'; run.font.color.rgb=RGBColor(0,0,0); run.bold=True; run.font.size=Pt(14 if level==1 else 12)
    return para

def page_break(doc): doc.add_page_break()

def add_page_num(paragraph):
    paragraph.alignment=WD_ALIGN_PARAGRAPH.CENTER
    run=paragraph.add_run('Page '); fld=OxmlElement('w:fldSimple'); fld.set(qn('w:instr'),'PAGE'); run._r.addnext(fld)

def build():
    make_er(); make_arch(); doc=Document(); sec=doc.sections[0]
    sec.left_margin=Inches(1.5); sec.right_margin=Inches(1); sec.top_margin=Inches(1); sec.bottom_margin=Inches(1)
    styles=doc.styles; styles['Normal'].font.name='Times New Roman'; styles['Normal'].font.size=Pt(12)
    for s in sec.footer.paragraphs: add_page_num(s)
    # Cover
    p(doc,'Vivekanand Education Society\'s Institute of Technology',True,align=WD_ALIGN_PARAGRAPH.CENTER)
    p(doc,'Department of Computer Engineering',True,align=WD_ALIGN_PARAGRAPH.CENTER)
    p(doc,'Academic Year 2026-27',align=WD_ALIGN_PARAGRAPH.CENTER)
    p(doc,'',align=WD_ALIGN_PARAGRAPH.CENTER); p(doc,'DBMS Micro Project Report',True,align=WD_ALIGN_PARAGRAPH.CENTER)
    p(doc,'Digital Banking System Database',True,align=WD_ALIGN_PARAGRAPH.CENTER)
    p(doc,'A Supabase PostgreSQL implementation with a role-aware web frontend',italic=True,align=WD_ALIGN_PARAGRAPH.CENTER)
    p(doc,'',align=WD_ALIGN_PARAGRAPH.CENTER); p(doc,'Course: Database Management System (DBMS)',align=WD_ALIGN_PARAGRAPH.CENTER)
    page_break(doc)
    heading(doc,'Index'); add_table(doc,['No.','Section'],[(1,'Introduction and Background'),(2,'Problem Statement'),(3,'Objectives and Scope'),(4,'Requirements and Data Requirements'),(5,'ER Diagram'),(6,'Flow Diagram and System Architecture'),(7,'Implementation and Database Operations'),(8,'Results and Working System Screenshots'),(9,'Conclusion and Future Scope')])
    p(doc,'This report is prepared according to the prescribed DBMS micro-project format. The implementation uses Supabase as the hosted PostgreSQL database and authentication platform.')
    page_break(doc)
    heading(doc,'1. Introduction and Background')
    p(doc,'Digital banking allows customers to access account information and perform financial operations through electronic channels. A banking database must maintain accurate account balances, transaction history, customer identity, branch information, and permissions. It must also preserve data integrity when multiple operations occur close together.')
    p(doc,'This project models a small digital banking system using Supabase. Supabase provides PostgreSQL tables, authentication, database functions, and Row Level Security. The system is designed to demonstrate how a real database supports online banking workflows rather than treating the interface as a collection of static screens.')
    p(doc,'The application separates the presentation layer from the data layer. The browser requests only the records that the signed-in user is allowed to see. A stored procedure performs transfers atomically so the debit, credit, and transaction record are treated as one logical operation.')
    page_break(doc)
    heading(doc,'2. Problem Statement')
    p(doc,'Small academic banking demonstrations often store customer and transaction details in unrelated files or in frontend variables. Such an approach makes it difficult to enforce relationships, prevent invalid balances, show transaction history, or explain how different users should access information.')
    p(doc,'The problem addressed by this project is the design of a normalized relational database that supports common digital banking tasks while protecting customer data. The solution must represent customers, branches, accounts, beneficiaries, and transactions; it must provide controlled access for customer, staff, and admin roles; and it must expose database operations through an understandable user interface.')
    page_break(doc)
    heading(doc,'3. Objectives and Scope')
    heading(doc,'3.1 Objectives',2)
    for x in ['Design a relational schema for core digital banking entities.','Apply primary keys, foreign keys, unique constraints, checks, indexes, and views.','Implement authentication-aware access using Supabase Row Level Security.','Provide an atomic money-transfer function using PostgreSQL transactions.','Build a basic frontend for dashboard viewing, balance lookup, transfers, and activity history.','Demonstrate SQL selection, joins, aggregation, updates, and stored procedure calls.'] : p(doc,'• '+x)
    heading(doc,'3.2 Scope',2)
    p(doc,'The project covers customer accounts, savings and current account types, branch association, beneficiaries, deposits, withdrawals, transfers, account status, and role-based visibility. It is an educational prototype and does not implement production banking integrations such as payment gateways, regulatory reporting, KYC document storage, OTP delivery, interest calculation, or a complete fraud-monitoring system.')
    page_break(doc)
    heading(doc,'4. Requirements and Data Requirements')
    heading(doc,'4.1 Functional Requirements',2)
    add_table(doc,['Requirement','Description'],[('Authentication','Users sign in through Supabase Auth.'),('Dashboard','Customers view their own accounts and balances.'),('Transfer','A signed-in customer can transfer to an active destination account.'),('History','Users view related completed and failed transactions.'),('Beneficiaries','Customers can maintain their own saved beneficiaries.'),('Staff review','Staff can review customer accounts and update account status.'),('Administration','Admins can manage operational records.')])
    heading(doc,'4.2 Non-Functional Requirements',2)
    p(doc,'The system should preserve confidentiality through RLS, consistency through constraints and foreign keys, availability through hosted database access, usability through a simple responsive UI, and maintainability through separated SQL scripts. Query performance is supported by indexes on account ownership and transaction timelines.')
    heading(doc,'4.3 Data Requirements',2)
    add_table(doc,['Entity','Important attributes'],[('Branches','branch code, name, address, city'),('Profiles','auth user ID, name, email, role, branch'),('Accounts','account number, owner, type, balance, status'),('Beneficiaries','owner, nickname, account number, bank, IFSC'),('Transactions','source, destination, amount, type, status, initiator, time')])
    page_break(doc)
    heading(doc,'5. ER Diagram')
    p(doc,'The ER model uses profiles as the authenticated customer or employee identity. One profile can own many accounts and beneficiaries. Each account belongs to one branch. Transactions may reference a source account, a destination account, or both for transfers. Foreign keys enforce valid relationships.')
    doc.add_picture(str(ASSET/'er_diagram.png'), width=Inches(6.2)); p(doc,'Figure 1: Entity relationship diagram for the Digital Banking System.',italic=True,align=WD_ALIGN_PARAGRAPH.CENTER)
    add_table(doc,['Relationship','Cardinality'],[('Branch to Account','One branch can have many accounts.'),('Profile to Account','One profile can own many accounts.'),('Profile to Beneficiary','One customer can save many beneficiaries.'),('Account to Transaction','An account can appear as a source or destination in many transactions.')])
    page_break(doc)
    heading(doc,'6. Flow Diagram and System Architecture')
    p(doc,'The frontend uses the publishable Supabase key. Authentication establishes the signed-in user. RLS policies then limit table access, while the transfer function validates ownership, balance, status, and destination account before updating records.')
    doc.add_picture(str(ASSET/'architecture.png'), width=Inches(6.2)); p(doc,'Figure 2: High-level architecture and access flow.',italic=True,align=WD_ALIGN_PARAGRAPH.CENTER)
    heading(doc,'6.1 Access Control Flow',2)
    p(doc,'Customer requests are filtered by auth.uid(). Staff and admin access is determined by the role stored in profiles. The role helper function is security definer and uses a restricted search path. The browser never receives the service-role key; all frontend access is intended to occur through the publishable key and database policies.')
    page_break(doc)
    heading(doc,'7. Implementation and Database Operations')
    heading(doc,'7.1 Schema Implementation',2)
    p(doc,'The database defines enum types for user roles, account types, account statuses, transaction types, and transaction statuses. These types reduce invalid values and make queries easier to interpret. Accounts use a non-negative balance check. Transactions require a positive amount and at least one related account.')
    heading(doc,'7.2 Database Operations Demonstrated',2)
    add_table(doc,['Operation','Example used in project','DBMS concept'],[('SELECT','Account summary and transaction history','Filtering and ordering'),('JOIN','Branch-wise balances','Relational association'),('GROUP BY','Daily transfer totals','Aggregation'),('INSERT','New beneficiary or transaction','Data creation'),('UPDATE','Profile phone or account status','Data modification'),('RPC function','Atomic transfer','Stored procedure and consistency'),('RLS policy','Own rows versus staff rows','Authorization')])
    heading(doc,'7.3 Atomic Transfer',2)
    p(doc,'The transfer_money function first validates a positive amount and distinct accounts. It deducts the amount only from an active account owned by the signed-in user and with sufficient balance. It then credits an active destination account and inserts a completed transaction record. If any validation fails, the function raises an exception and the operation does not produce a successful transfer.')
    page_break(doc)
    heading(doc,'7.4 Security and Permissions')
    add_table(doc,['Role','Permitted access'],[('Customer','View own profile, accounts, beneficiaries, and related transactions; initiate transfers.'),('Staff','Review customer and account records; update account status under policy.'),('Admin','Operational management across project tables and records.')])
    p(doc,'Row Level Security is enabled on the core tables. This is important because the frontend is not treated as a security boundary. Even if a user changes a browser request, the database policies determine whether the request can read or write a row.')
    heading(doc,'7.5 Frontend Implementation',2)
    p(doc,'The frontend contains an authentication panel, dashboard summary cards, account list, recent activity list, transfer form, and staff review area. It also includes a demo preview so the interface can be shown before live Supabase credentials are added. In the connected version, data is loaded from Supabase tables and transfers call the database function through the client RPC API.')
    page_break(doc)
    heading(doc,'7.6 SQL Command Samples')
    p(doc,'The following commands are included in the project so the database can be demonstrated directly in the Supabase SQL Editor.')
    add_table(doc,['Command category','Demonstration'],[('DDL','CREATE TABLE, CREATE TYPE, CREATE INDEX, CREATE VIEW'),('DML','INSERT branch, UPDATE profile, and stored transaction insert'),('DQL','SELECT account summary, JOIN branches, GROUP BY transfer totals'),('Security','ALTER TABLE ENABLE ROW LEVEL SECURITY and CREATE POLICY'),('Procedural','SELECT transfer_money(...) for an atomic transfer')])
    p(doc,'A useful demonstration sequence is to run the account summary query as a customer, run the same query with a different user, and then run the branch-wise aggregation as staff. The result difference shows that database permissions are part of the system behavior.')
    heading(doc,'7.7 Data Dictionary',2)
    add_table(doc,['Table','Key fields','Purpose'],[('branches','branch_id, branch_code','Stores physical branch information.'),('profiles','user_id, role, branch_id','Connects Auth identity to banking profile and role.'),('accounts','account_id, account_number, balance','Stores customer accounts and current balance.'),('beneficiaries','beneficiary_id, user_id','Stores saved transfer destinations.'),('transactions','transaction_id, amount, status','Stores financial activity and audit history.')])
    page_break(doc)
    heading(doc,'8. Results and Working System Screenshots')
    p(doc,'The initial working interface has been prepared with a responsive layout and demo data. After the Supabase project is connected, the following evidence should be captured for the final submission:')
    for x in ['Supabase table editor showing branches, profiles, accounts, beneficiaries, and transactions.','SQL Editor showing schema execution and successful demonstration queries.','Auth users showing customer, staff, and admin test users.','Policies page showing Row Level Security enabled.','Customer dashboard showing account balance and recent transactions.','Transfer result showing the updated balances and inserted transaction record.','Staff review screen showing role-specific account visibility.'] : p(doc,'• '+x)
    heading(doc,'8.1 Expected Results',2)
    add_table(doc,['Test case','Expected result'],[('Customer reads accounts','Only accounts owned by signed-in customer are returned.'),('Customer reads another profile','Request is rejected or returns no row.'),('Valid transfer','Source decreases, destination increases, transaction is inserted.'),('Insufficient balance','Function raises an error and balances remain unchanged.'),('Staff account review','Staff can see account records under staff policy.'),('Invalid amount','Database check/function rejects zero or negative amount.')])
    page_break(doc)
    heading(doc,'8.2 Test Plan and Demonstration Evidence')
    p(doc,'Testing combines database-level checks with interface-level checks. Each test should be run after the Supabase project has been configured with Auth users and sample accounts.')
    add_table(doc,['Test ID','Action','Expected evidence'],[('T01','Sign in as customer','Customer dashboard opens and role badge shows CUSTOMER.'),('T02','Load accounts','Only the signed-in customer accounts appear.'),('T03','Enter an invalid destination','The interface displays destination-not-found feedback.'),('T04','Transfer an amount within balance','Balances and recent activity update.'),('T05','Transfer more than balance','The function raises an error; no partial balance update occurs.'),('T06','Sign in as staff','Staff review section becomes visible.'),('T07','Inspect RLS','Unauthorized rows are not returned.')])
    p(doc,'For the final viva, the demonstrator should show the UI action and then immediately show the corresponding database row or balance change in the SQL Editor. This connects the visible frontend behavior to the underlying DBMS operations.')
    heading(doc,'8.3 Limitations of the Prototype',2)
    p(doc,'The academic prototype uses a simple browser client and a single database function for transfers. It does not claim to be a production banking application. Real deployment would require additional security review, secrets management, audit retention, rate limiting, monitoring, compliance controls, and integration testing.')
    page_break(doc)
    heading(doc,'Appendix A: Project Demonstration Procedure')
    for x in ['Open the Supabase project and run schema.sql in the SQL Editor.','Run policies.sql and confirm that RLS is enabled on the five core tables.','Create three Auth users and insert matching profile rows with customer, staff, and admin roles.','Insert sample accounts linked to the customer profile and add one beneficiary.','Open the frontend and replace the Supabase URL and publishable key placeholders.','Use the demo preview first to explain the interface, then sign in to show live database data.','Perform a valid transfer and verify the account balances and transaction record.','Repeat the operation with an insufficient balance to demonstrate atomic failure handling.'] : p(doc,'• '+x)
    heading(doc,'Appendix B: Submission Checklist',2)
    add_table(doc,['Item','Status'],[('Supabase schema script','Included'),('Seed and setup guidance','Included'),('RLS policies','Included'),('Demonstration queries','Included'),('Frontend scaffold','Included'),('ER diagram','Included in report'),('System architecture diagram','Included in report'),('Live screenshots','To capture after Supabase setup'),('Final report formatting','Applied to DOCX draft')])
    page_break(doc)
    heading(doc,'9. Conclusion and Future Scope')
    p(doc,'The Digital Banking System Database demonstrates how a relational database supports a realistic banking workflow. The design combines normalized entities, constraints, indexes, a summary view, a stored procedure, authentication, and Row Level Security. The frontend makes the database operations visible through a dashboard and transfer workflow.')
    p(doc,'The project also demonstrates an important DBMS principle: correctness and access control belong in the database layer as well as the application layer. A customer should not be able to see another customer’s balance merely because a frontend request was modified. The policies and ownership conditions provide that protection at the data source.')
    heading(doc,'9.1 Future Scope',2)
    for x in ['Add OTP or multi-factor authentication for sensitive actions.','Add beneficiary verification and transfer limits.','Introduce an audit log for staff and admin actions.','Add scheduled payments, bill payments, and notifications.','Add fraud rules and unusual-activity alerts.','Deploy the frontend through a secure hosting platform and connect it to a production Supabase project.'] : p(doc,'• '+x)
    heading(doc,'References')
    p(doc,'Supabase Documentation, PostgreSQL Documentation, and the supplied DBMS Micro Project Report format.')
    output=OUT/'Digital_Banking_System_DBMS_Report.docx'; doc.save(output); print(output)

if __name__=='__main__': build()
