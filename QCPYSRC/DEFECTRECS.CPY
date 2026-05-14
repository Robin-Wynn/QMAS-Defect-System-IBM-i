      *================================================================*
      * COPYBOOK: DEFECTRECS                                           *
      * PURPOSE:  Shared record layout for DEFECTPF                    *
      *           Used by: QMASBATCH, QMASINT                          *
      *----------------------------------------------------------------*
      * DEFECT-RECORD                                                  *
      * Primary layout - mirrors DEFECTPF column for column.           *
      * Use for host variable groups and general record passing.       *
      *----------------------------------------------------------------*
       01  DR-DEFECT-REC.
      *--- Key field --------------------------------------------------*
           05 DR-DEFID    PIC X(8).
      *--- Production identifiers -------------------------------------*
           05 DR-LINE     PIC X(4).
           05 DR-PARTNO   PIC X(10).
      *--- Defect type ------------------------------------------------*
           05 DR-TYPECD   PIC 9(2).
           05 DR-TYPEDESC PIC X(30).
      *--- Severity ---------------------------------------------------*
           05 DR-SEV      PIC 9(1).
               88 DR-SEV-CRITICAL VALUE 1.
               88 DR-SEV-MAJOR    VALUE 2.
               88 DR-SEV-MINOR    VALUE 3.
      *--- Cost fields ------------------------------------------------*
           05 DR-BCOST    PIC 9(9)V99.
           05 DR-TCOST    PIC 9(11)V99.
      *--- Detection stage --------------------------------------------*
           05 DR-STAGE    PIC X(2).
               88 DR-STAGE-RAWMAT   VALUE 'RW'.
               88 DR-STAGE-INPROC   VALUE 'IP'.
               88 DR-STAGE-FINGOODS VALUE 'FG'.
      *--- Rework flag ------------------------------------------------*
           05 DR-RWK      PIC X(1).
               88 DR-RWK-YES VALUE 'Y'.
               88 DR-RWK-NO  VALUE 'N'.

      *================================================================*
      * DR-DEFECT-DISPLAY                                              *
      * Edited display layout - for use in the interactive program     *
      * (QMASINT) screen fields and subfile output columns.            *
      *================================================================*
       01  DR-DEFECT-DISPLAY.
           05  DD-DEFID        PIC X(8).
           05  DD-LINE         PIC X(4).
           05  DD-PARTNO       PIC X(10).
           05  DD-TYPECD       PIC Z9.
           05  DD-TYPEDESC     PIC X(30).
           05  DD-SEV          PIC 9.
           05  DD-BCOST        PIC Z(7)9.99.
           05  DD-TCOST        PIC Z(9)9.99.
           05  DD-STAGE        PIC X(2).
           05  DD-RWK          PIC X(1).

      *================================================================*
      * DR-CRITICAL-ESCAPE-SW                                          *
      * Set this switch after loading DR-DEFECT-RECORD.                *
      * Used by QMASINT to trigger the CRITICAL ESCAPE warning.        *
      *================================================================*
       01  DR-CRITICAL-ESCAPE-SW   PIC X VALUE 'N'.
           88  DR-CRITICAL-ESCAPE      VALUE 'Y'.
           88  DR-NOT-CRITICAL-ESCAPE  VALUE 'N'.