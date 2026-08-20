# ACCTMGMT — Batch Banking System in OS/VS COBOL

Account management system developed and debugged on a simulated mainframe Hercules 3.07 / MVS 3.8j (TK5), using the OS/VS COBOL compiler (IKFCBL00) and Linkage Editor (HEWL). The program processes deposits, withdrawals, and balance inquiries through an interactive menu simulated via batch (SYSIN).

---

**1. Environment Architecture**

```text
+-----------------------------------------------------------------------------------+
| 3.07 (Linux host)                                                        Hercules |
|  | MVS 3.8j — Distribution TK5R                                                   |
|  |  | TSO | JES2 | Spool (DASD) | HERC01 -> (batch dasd/spool0.249)             |
|  |  | PDS: HERC01.BANKING.COBOL(ACCTMGMT) <- COBOL source                         |
|  |  | PDS: HERC01.BANKING.JCL(HERC01C) <- control JCL                            |
|  |  | PDS: HERC01.BANKING.LOAD(ACCTMGMT) <- load module                           |
|  |  +-----------------------------------------------------------------------------+
|  +--------------------------------------------------------------------------------+
| Terminal (c3270) — TCP access on :3270                                            |
+-----------------------------------------------------------------------------------+

JCL execution flow (3 steps):
COBCOMP (IKFCBL00) ---> LKED (HEWL) ---> RUNBANK (ACCTMGMT)
  |                       |                |
  +--> &&LOADSET ---------+                +--> SYSOUT (menu + results)
Step	Program	Function
COBCOMP	IKFCBL00	Compiles the COBOL source into a temporary object deck (&&LOADSET)
LKED	HEWL	Link-edits the object deck into an executable load module inside the LOAD PDS
RUNBANK	ACCTMGMT	Executes the program, reading simulated transactions from SYSIN
2. Technical Environment

Component: Value

Emulator: Hercules 3.07 (SDL Hyperion 4.9.1.0)

Guest operating system: MVS 3.8j — Distribution TK5R

COBOL compiler: OS/VS COBOL — IKFCBL00

Linkage Editor: HEWL

Batch subsystem: JES2

TSO user: HERC01

Terminal: c3270 (3270 over TCP, port 3270)

COBOL PDS: HERC01.BANKING.COBOL(ACCTMGMT)

JCL PDS: HERC01.BANKING.JCL(HERC01C)

Load Module: HERC01.BANKING.LOAD(ACCTMGMT)

DB2: Not available in this TK5 image — see section 6

3. JCL — HERC01C.jcl

Code snippet
//HERC01C JOB (COBOL),'ACCTMGMT',CLASS=A,MSGCLASS=X,REGION=4096K,
// NOTIFY=HERC01
//*
//* 1. COBOL COMPILATION
//COBCOMP EXEC PGM=IKFCBL00,
// PARM='LOAD,NODECK,LIB,SIZE=2048K,QUOTE'
//SYSLIB   DD DSN=HERC01.BANKING.COBOL,DISP=SHR
//SYSIN    DD DSN=HERC01.BANKING.COBOL(ACCTMGMT),DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(MOD,PASS),UNIT=SYSDA,
//            SPACE=(TRK,(3,3))
//SYSPRINT DD SYSOUT=A
//SYSPUNCH DD DUMMY
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//*
//* 2. LINKAGE EDITOR
//LKED    EXEC PGM=HEWL,PARM='LIST,XREF,LET,MAP',COND=(4,LT)
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//SYSLIB   DD DSN=SYS1.COBLIB,DISP=SHR
//         DD DSN=SYS1.LINKLIB,DISP=SHR
//SYSLMOD  DD DSN=HERC01.BANKING.LOAD(ACCTMGMT),DISP=SHR
//SYSPRINT DD SYSOUT=A
//*
//* 3. EXECUTION OF THE COMPILED PROGRAM
//RUNBANK EXEC PGM=ACCTMGMT
//STEPLIB  DD DSN=HERC01.BANKING.LOAD,DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
1
0000000001
000010000
2
0000000001
000050000
3
0000000001
9
/*
Note on SYSIN: Every transaction that involves an amount requires 3 cards (menu choice -> 10-digit account -> 9-digit amount with 2 implied decimals), and the balance inquiry requires 2 (menu choice -> account).

4. COBOL Program — ACCTMGMT (Final Corrected Version)

COBOL
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTMGMT.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 ACCOUNT-REG.
          05 ACCOUNT-ID       PIC 9(10).
          05 BALANCE          PIC 9(7)V99 COMP-3 VALUE 500.00.
          05 ACCOUNT-STATUS   PIC X(10)   VALUE "ACTIVE".

       01 CUSTOMER-REG.
          05 CUSTOMER-ID      PIC 9(10).
          05 FIRST-NAME       PIC X(20).
          05 LAST-NAME        PIC X(20).

       01 TRANSACTIONS-REG.
          05 TRANSACTION-ID   PIC 9(10).
          05 ACCOUNT-ID       PIC 9(10).
          05 AMOUNT           PIC 9(7)V99 COMP-3.
          05 TRANSACTION-DATE PIC 9(8).
          05 TRANSACTION-TYPE PIC X(10).

       01 WS-TRANSACTION-COUNTER PIC 9(10) VALUE 0.
       01 WS-MENU-CHOICE         PIC X(1).
       01 WS-TEMP-AMOUNT         PIC 9(7)V99.
       01 WS-DATE-TEMP.
          05 WS-CENTURY        PIC 9(2) VALUE 20.
          05 WS-DATE-YYMMDD    PIC 9(6).

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM MENU-LOOP UNTIL WS-MENU-CHOICE = "9".
           GOBACK.

       MENU-LOOP.
           DISPLAY "====================================".
           DISPLAY "MAIN MENU".
           DISPLAY "====================================".
           DISPLAY "1-DEPOSIT  2-WITHDRAWAL  3-BALANCE  9-EXIT".
           ACCEPT WS-MENU-CHOICE.
           IF WS-MENU-CHOICE = "1"
               PERFORM GET-ACCOUNT-ID
               PERFORM GET-AMOUNT
               PERFORM GET-TRANSACTION-ID
               PERFORM PROCESS-DEPOSIT
           ELSE
           IF WS-MENU-CHOICE = "9"
               NEXT SENTENCE
           ELSE
           IF WS-MENU-CHOICE = "2"
               PERFORM GET-ACCOUNT-ID
               PERFORM GET-AMOUNT
               PERFORM GET-TRANSACTION-ID
               PERFORM PROCESS-WITHDRAWAL
           ELSE
           IF WS-MENU-CHOICE = "3"
               PERFORM GET-ACCOUNT-ID
               PERFORM PROCESS-BALANCE-INQUIRY
           ELSE
               DISPLAY "INVALID OPTION".

       GET-ACCOUNT-ID.
           DISPLAY "ENTER ACCOUNT ID NUMBER".
           ACCEPT ACCOUNT-ID OF ACCOUNT-REG.

       GET-AMOUNT.
           DISPLAY "AMOUNT OF TRANSACTION".
           ACCEPT WS-TEMP-AMOUNT.
           MOVE WS-TEMP-AMOUNT TO AMOUNT.

       GET-TRANSACTION-ID.
           ADD 1 TO WS-TRANSACTION-COUNTER.
           MOVE WS-TRANSACTION-COUNTER TO TRANSACTION-ID.
           MOVE WS-DATE-TEMP TO TRANSACTION-DATE.

       PROCESS-DEPOSIT.
           IF ACCOUNT-STATUS = "ACTIVE"
               MOVE "DEPOSIT" TO TRANSACTION-TYPE
               MOVE ACCOUNT-ID OF ACCOUNT-REG TO ACCOUNT-ID OF TRANSACTIONS-REG
               ADD AMOUNT TO BALANCE
           ELSE
               MOVE "REJECTED" TO TRANSACTION-TYPE.

       PROCESS-WITHDRAWAL.
           MOVE ACCOUNT-ID OF ACCOUNT-REG TO ACCOUNT-ID OF TRANSACTIONS-REG.
           IF ACCOUNT-STATUS = "ACTIVE" AND BALANCE NOT LESS THAN AMOUNT
               MOVE "WITHDRAWAL" TO TRANSACTION-TYPE
               SUBTRACT AMOUNT FROM BALANCE
           ELSE
               MOVE "REJECTED" TO TRANSACTION-TYPE.

       PROCESS-BALANCE-INQUIRY.
           MOVE ACCOUNT-ID OF ACCOUNT-REG TO ACCOUNT-ID OF TRANSACTIONS-REG.
           IF ACCOUNT-STATUS = "ACTIVE"
               DISPLAY "CURRENT BALANCE: " BALANCE
           ELSE
               DISPLAY "ACCOUNT NOT ACTIVE".
Data Structures (Logical Records)

ACCOUNT-REG

ACCOUNT-ID PIC 9(10): Account identifier.

BALANCE PIC 9(7)V99 COMP-3: Current balance (packed decimal).

ACCOUNT-STATUS PIC X(10): Account status (ACTIVE/...).

CUSTOMER-REG

CUSTOMER-ID PIC 9(10): Customer identifier.

FIRST-NAME PIC X(20): First name.

LAST-NAME PIC X(20): Last name.

TRANSACTIONS-REG

TRANSACTION-ID PIC 9(10): Transaction sequence number.

ACCOUNT-ID PIC 9(10): Affected account.

AMOUNT PIC 9(7)V99 COMP-3: Transaction amount.

TRANSACTION-DATE PIC 9(8): Date (CCYYMMDD).

TRANSACTION-TYPE PIC X(10): DEPOSIT / WITHDRAWAL / REJECTED.

Note: In the current version, CUSTOMER-REG is defined but not integrated into the business logic (no PERFORM uses it). It remains an extension point — see section 6.

5. Development and Debugging History

Complete log of the incidents found and resolved during development, in chronological order:

5.1 COBOL date syntax error (IKF3001I-E DATE NOT DEFINED)

Cause: Use of ACCEPT ... FROM DATE, syntax not supported by IKFCBL00 on MVS 3.8j.

Fix: Replaced with MOVE CURRENT-DATE TO TRANSACTION-DATE and corrected missing periods at the end of paragraphs (IKF1043I-W).

5.2 Infinite loop and log explosion ($HASP375)

Cause: A typo in the JCL — //SYSOUT DD * duplicated instead of //SYSIN DD *. COBOL's ACCEPT reads from SYSIN by default; with that DD missing, it read null values indefinitely inside a PERFORM UNTIL, generating more than 7.6 million lines in seconds.

5.3 JES2 Spool collapse ($HASP355 / terminal stuck in X Wait)

Cause: The line volume from the previous incident filled the spool disk to 100%. TSO/ISPF could no longer register I/O. Failed attempt: purge commands (/$p outall, /$p A,ALL) failed with INVALID OPERAND due to limitations of the JES2 release in TK5.

Fix applied: Full shutdown and restart of Hercules.

5.4 JES2 checkpoint damaged after an abrupt quit

Cause: The Hercules quit command was used directly (without a LOGOFF / orderly JES2 shutdown first), leaving the spool checkpoint dataset with an orphaned lock.

Symptom on the next IPL: $HASP486 SPOOL0 DAMAGED CHECKPOINT DATA SET DETECTED -- REPLY Y OR N TO CONTINUE / $HASP479 UNABLE TO OBTAIN CKPT DATA SET LOCK -- REPLY Y OR N TO CONTINUE.

Fix: Formal reply to the WTOR from the Hercules console with the / prefix (required to direct the command to the MVS guest, not to Hercules itself): /r 0,y / /r 1,y. After the JES2 warm-start, it was verified that no orphaned jobs remained, using /$d a,all -> NO ACTIVE JOBS.

5.5 Logic bug — comparison against incompatible literal types

Cause: MENU-LOOP compared TRANSACTION-TYPE (the input field) against text literals ("DEPOSIT", "EXIT", "WITHDRAWAL", "BALANCE"), but SYSIN was sending numeric codes (1, 2, 3, 9). No comparison ever matched, always falling into DISPLAY "INVALID OPTION" and, once SYSIN was exhausted, reproducing the infinite loop from incident 5.2 (confirmed by an ABEND SB37 due to SYSOUT running out of space).

Fix: Introduced the field 01 WS-MENU-CHOICE PIC X(1) to separate the menu selection from the business field TRANSACTION-TYPE, and rewrote MENU-LOOP and the exit condition in MAIN-PROCEDURE (PERFORM MENU-LOOP UNTIL WS-MENU-CHOICE = "9") to compare against the actual numeric codes.

5.6 Logic bug — transaction amount never transferred

Cause: GET-AMOUNT read the value into WS-TEMP-AMOUNT but never moved it into the AMOUNT field of TRANSACTIONS-REG, which was left with undefined content (risk of S0C7 when used in COMP-3 arithmetic).

Fix: Added MOVE WS-TEMP-AMOUNT TO AMOUNT at the end of GET-AMOUNT.

5.7 ABEND S0C7 (Data Exception) due to misaligned SYSIN

Cause: The original SYSIN had only 6 cards (1, 100, 2, 500, 3, 9), but the program performs 3 ACCEPTs per transaction that includes an amount (menu, account, amount). The cards became misaligned: e.g. 100 was read as ACCOUNT-ID and 2 as WS-TEMP-AMOUNT, producing an invalid packed decimal when executing ADD AMOUNT TO BALANCE.

Fix: Rebuilt SYSIN respecting the exact width of each PIC (ACCOUNT-ID = 10 digits, amount = 9 digits with 2 implied decimals) and the real order of the ACCEPT statements.

Final result:
COBCOMP RC=0004 (warning IKF4072I-W, non-blocking) -> LKED RC=0000 -> RUNBANK RC=0000

Business validation (starting balance 500.00):
Deposit +100.00 -> 600.00 | Withdrawal -500.00 -> 100.00 | Final balance inquiry -> CURRENT BALANCE: 000010000 = $100.00 ✔

6. Database Schema (DB2) — Proposed Design

Important note: This Hercules/TK5 image does not include DB2 (Database 2 for MVS would require an additional installation and licensing not available in this lab environment). The current ACCTMGMT program uses records in WORKING-STORAGE (in-memory, no persistence between executions) instead of accessing a real database through EXEC SQL.

The schema below is a reference design documenting how persistence would be structured if the program were migrated to DB2, keeping a 1:1 mapping with the COBOL records already defined. It serves as a specification for a future migration.

6.1 Entity-Relationship Diagram (Conceptual)

Plaintext
+-----------------------+         +-----------------------+
|       CUSTOMER        |         |        ACCOUNT        |
+-----------------------+         +-----------------------+
| PK  CUSTOMER_ID       |1       *| PK  ACCOUNT_ID        |
|     FIRST_NAME        |<--------| FK  CUSTOMER_ID       |
|     LAST_NAME         |         |     BALANCE           |
+-----------------------+         |     ACCOUNT_STATUS    |
                                  +-----------------------+
                                              | 1
                                              |
                                              | *
                                  +-----------------------+
                                  |      TRANSACTION      |
                                  +-----------------------+
                                  | PK  TRANSACTION_ID    |
                                  | FK  ACCOUNT_ID        |
                                  |     AMOUNT            |
                                  |     TXN_DATE          |
                                  |     TXN_TYPE          |
                                  +-----------------------+
6.2 DDL — Table Creation

SQL
-- TABLESPACE AND DATABASE (DB2 for z/OS convention)
CREATE DATABASE BANKDB;

CREATE TABLESPACE TSBANK IN BANKDB
    USING STOGROUP SYSDEFLT
    PRIQTY 720 SECQTY 720
    BUFFERPOOL BP0
    LOCKSIZE PAGE
    SEGSIZE 4;

-- CUSTOMER — equivalent to CUSTOMER-REG
CREATE TABLE BANKADM.CUSTOMER (
    CUSTOMER_ID DECIMAL(10,0) NOT NULL,
    FIRST_NAME  CHAR(20)      NOT NULL,
    LAST_NAME   CHAR(20)      NOT NULL,
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (CUSTOMER_ID)
) IN BANKDB.TSBANK;

-- ACCOUNT — equivalent to ACCOUNT-REG
CREATE TABLE BANKADM.ACCOUNT (
    ACCOUNT_ID     DECIMAL(10,0) NOT NULL,
    CUSTOMER_ID    DECIMAL(10,0) NOT NULL,
    BALANCE        DECIMAL(9,2)  NOT NULL DEFAULT 0.00,
    ACCOUNT_STATUS CHAR(10)      NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT PK_ACCOUNT PRIMARY KEY (ACCOUNT_ID),
    CONSTRAINT FK_ACCOUNT_CUSTOMER FOREIGN KEY (CUSTOMER_ID)
        REFERENCES BANKADM.CUSTOMER (CUSTOMER_ID) ON DELETE RESTRICT,
    CONSTRAINT CK_ACCOUNT_STATUS CHECK (ACCOUNT_STATUS IN ('ACTIVE', 'INACTIVE', 'CLOSED')),
    CONSTRAINT CK_BALANCE_NONNEG CHECK (BALANCE >= 0)
) IN BANKDB.TSBANK;

-- TRANSACTIONS — equivalent to TRANSACTIONS-REG
CREATE TABLE BANKADM.TRANSACTIONS (
    TRANSACTION_ID DECIMAL(10,0) NOT NULL,
    ACCOUNT_ID     DECIMAL(10,0) NOT NULL,
    AMOUNT         DECIMAL(9,2)  NOT NULL,
    TXN_DATE       DATE          NOT NULL,
    TXN_TYPE       CHAR(10)      NOT NULL,
    CONSTRAINT PK_TRANSACTIONS PRIMARY KEY (TRANSACTION_ID),
    CONSTRAINT FK_TXN_ACCOUNT FOREIGN KEY (ACCOUNT_ID)
        REFERENCES BANKADM.ACCOUNT (ACCOUNT_ID) ON DELETE RESTRICT,
    CONSTRAINT CK_TXN_TYPE CHECK (TXN_TYPE IN ('DEPOSIT', 'WITHDRAWAL', 'REJECTED')),
    CONSTRAINT CK_AMOUNT_POS CHECK (AMOUNT > 0)
) IN BANKDB.TSBANK;

-- Supporting indexes for frequent queries
CREATE INDEX BANKADM.IX_TXN_ACCOUNT 
    ON BANKADM.TRANSACTIONS (ACCOUNT_ID, TXN_DATE);

CREATE INDEX BANKADM.IX_ACCOUNT_CUSTOMER 
    ON BANKADM.ACCOUNT (CUSTOMER_ID);
6.3 COBOL <-> DB2 Mapping

COBOL Field (WORKING-STORAGE)	DB2 Column	Comment
ACCOUNT-ID PIC 9(10)	ACCOUNT.ACCOUNT_ID (DECIMAL(10,0))	Primary key
BALANCE PIC 9(7)V99 COMP-3	ACCOUNT.BALANCE (DECIMAL(9,2))	COBOL packed decimal maps directly to SQL DECIMAL
ACCOUNT-STATUS PIC X(10)	ACCOUNT.ACCOUNT_STATUS (CHAR(10))	Constrained with CHECK instead of validated only inside the program
CUSTOMER-ID / FIRST-NAME / LAST-NAME	CUSTOMER table	Currently unused in the logic — see section 6.4
TRANSACTION-ID	TRANSACTIONS.TRANSACTION_ID	Sequence number — in DB2, a candidate for GENERATED ALWAYS AS IDENTITY
AMOUNT	TRANSACTIONS.AMOUNT	—
TRANSACTION-DATE PIC 9(8)	TRANSACTIONS.TXN_DATE (DATE)	Requires conversion from 9(8) to a native DATE type
TRANSACTION-TYPE	TRANSACTIONS.TXN_TYPE	—
6.4 Extension Points for the Real Migration

Real persistence between executions: Today, BALANCE resets to 500.00 every time the job runs (VALUE 500.00 in WORKING-STORAGE). With DB2, the balance would be read via EXEC SQL SELECT at the start of each transaction and updated with EXEC SQL UPDATE, surviving across batch executions.

Integration of CUSTOMER-REG: The customer record exists in the COBOL source but is unused — with the CUSTOMER table, one could validate that ACCOUNT.CUSTOMER_ID exists before operating on the account.

Multiple accounts: The current program handles a single "in-memory account"; with DB2, each ACCOUNT-ID read from SYSIN would correspond to a distinct row, allowing operations on multiple real accounts in the same run.

Auditing: The TRANSACTIONS table naturally becomes an audit log (every INSERT, including REJECTED ones), something the current version only exposes via DISPLAY in SYSOUT.

7. Known Pending Items

Compiler warning IKF4072I-W (cards 55, 75, 84, 91): The compiler assumes the end of a PERFORM-ed paragraph due to a missing explicit period before the next paragraph, within the nested IF/ELSE structure of MENU-LOOP, PROCESS-DEPOSIT, and PROCESS-WITHDRAWAL. It does not affect the current result, but it is recommended to fix it (adding the missing terminating period on each nested IF) before scaling up the program's complexity.

CUSTOMER-REG not integrated: Not integrated into the business logic.

No real persistence: The account state lives only for the duration of the job execution (see section 6.4).

DB2 migration pending: Either a Hercules/TK5 image with DB2 installed, or porting the logic to a relational engine reachable from this environment.

8. Base Environment Credits

MVS 3.8j Turnkey System: TK3 by Volker Bandke, TK4- by Juergen Winkelmann, TK5 by Rob Prins.

Hercules SDL Hyperion: Roger Bowler, Jan Jaeger, and contributors.
