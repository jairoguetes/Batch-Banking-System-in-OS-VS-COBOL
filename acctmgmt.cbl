       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTMGMT.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
        01 ACCOUNT-REG.
           05 ACCOUNT-ID       PIC 9(10).
           05 BALANCE          PIC 9(7)V99 COMP-3 VALUE 500.00.
           05 ACCOUNT-STATUS   PIC X(10) VALUE "ACTIVE".
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
        01 WS-MENU-CHOICE    PIC X(1).
        01 WS-TEMP-AMOUNT    PIC 9(7)V99.
        01 WS-DATE-TEMP.
           05 WS-CENTURY      PIC 9(2)    VALUE 20.
           05 WS-DATE-YYMMDD  PIC 9(6).
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM MENU-LOOP UNTIL WS-MENU-CHOICE = "9".
           GOBACK.

       MENU-LOOP.
               DISPLAY "========================================"
               DISPLAY "MAIN MENU"
               DISPLAY "========================================"
               DISPLAY "1-DEPOSIT  2-WITHDRAWAL  3-BALANCE  9-EXIT"
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
           DISPLAY "ENTER ACCOUNT ID NUMBER"
           ACCEPT ACCOUNT-ID OF ACCOUNT-REG.
       GET-AMOUNT.
           DISPLAY "AMOUNT OF TRANSACTION"
           ACCEPT WS-TEMP-AMOUNT.
           MOVE WS-TEMP-AMOUNT TO AMOUNT.
       GET-TRANSACTION-ID.
           ADD 1 TO WS-TRANSACTION-COUNTER
           MOVE WS-TRANSACTION-COUNTER TO
            TRANSACTION-ID.
           MOVE WS-DATE-TEMP TO TRANSACTION-DATE.
       PROCESS-DEPOSIT.
           IF ACCOUNT-STATUS = "ACTIVE"
             MOVE "DEPOSIT" TO TRANSACTION-TYPE
             MOVE ACCOUNT-ID OF ACCOUNT-REG TO
              ACCOUNT-ID OF TRANSACTIONS-REG
             ADD AMOUNT TO BALANCE
           ELSE
                MOVE "REJECTED" TO TRANSACTION-TYPE.
       PROCESS-WITHDRAWAL.
           MOVE ACCOUNT-ID OF ACCOUNT-REG TO
            ACCOUNT-ID OF TRANSACTIONS-REG
           IF ACCOUNT-STATUS = "ACTIVE" AND
               BALANCE NOT LESS THAN AMOUNT
               MOVE "WITHDRAWAL" TO TRANSACTION-TYPE
               SUBTRACT AMOUNT FROM BALANCE
           ELSE
                   MOVE "REJECTED" TO TRANSACTION-TYPE.
       PROCESS-BALANCE-INQUIRY.
           MOVE ACCOUNT-ID OF ACCOUNT-REG TO
            ACCOUNT-ID OF TRANSACTIONS-REG
           IF ACCOUNT-STATUS = "ACTIVE"
               DISPLAY "CURRENT BALANCE: " BALANCE
           ELSE
               DISPLAY "ACCOUNT NOT ACTIVE".
