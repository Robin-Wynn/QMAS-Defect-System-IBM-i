# QMAS — Quality Metrics & Analysis System

> A full-stack IBM i / COBOL application for manufacturing defect ingestion, cost analysis, and interactive audit — built as a capstone project for the NeXTLegacy COBOL program.

---

## 📋 Project Overview

QMAS is a production-style IBM i application that solves a real manufacturing problem: getting defect data off the shop floor, calculating its true financial impact, and putting it in front of the managers who need to act on it.

The system has two sides:

- **Batch side** — reads a CSV file of defect records, validates each one, calls a subprogram to calculate total cost using severity and stage multipliers from a DB2 lookup table, then upserts every record into a DB2 physical file.
- **Interactive side** — a classic 5250 green-screen interface where shop floor managers can filter defects by production line, severity, and detection stage, browse a scrollable list, and drill into individual records. Critical defects that escaped to finished goods trigger a reverse-image warning on screen.

---

## 🛠 Tech Stack

| Technology | Usage |
|---|---|
| **ILE COBOL** | Batch program, subprogram, interactive program |
| **IBM i (AS/400)** | Operating platform, V7R5 |
| **DB2 for i** | Relational database — DEFECTPF table, QRSC lookup tables |
| **DDS** | 5250 display file with subfile (QMASDSPF) |
| **CL (Control Language)** | Wrapper program for job automation and scheduling |
| **Embedded SQL** | INSERT, UPDATE, SELECT within COBOL via EXEC SQL |
| **IBM i Job Scheduler** | Automated nightly batch execution |

---

## 📁 Repository Structure

```
QMAS-Defect-System/
│
├── QCBLLESRC/                        COBOL source programs
│   ├── QMASBATCH.cblle         Batch integration program
│   ├── QMASTCOST.cblle         TCOST calculation subprogram
│   └── QMASINT.cblle           Interactive management console
│
├── QCLSRC/                         Control Language
│   └── CLWRAP.clle             CL wrapper — job setup and submission
│
├── QDDSSRC/                        Data Description Specifications
│   └── QMASDSPF.dspf           Display file — all three 5250 screens
│
├── QCPYSRC/                  Shared record layouts
│   └── DEFECTRECS.cpy          Shared defect record copybook
│
├── QSQLSRC/                        Database definitions
│   └── DEFTABLE.sql            CREATE TABLE for DEFECTPF
│
└── docs/                       Documentation
    └── QMAS_RunSheet.pdf       Operational run sheet
```

---

## 🔄 System Flow

```
CSV Input (QRSC/CSVIN)
        │
        ▼
  CLWRAP (CL Wrapper)
  - Adds libraries to list
  - Overrides CSVIN to QRSC
  - Submits QMASBATCH
        │
        ▼
  QMASBATCH (Batch Program)
  - Reads CSV record by record
  - Skips header row
  - Parses 9 fields via UNSTRING
  - Validates DEFID, STAGE, field count
  - Calls QMASTCOST subprogram
        │
        ├──► QMASTCOST (Subprogram)
        │    - Looks up SEVERITY_VALUE from QRSC.SEVERITY
        │    - Looks up STAGE_VALUE from QRSC.DETSTAGE
        │    - Computes TCOST = BCOST × SEV_VALUE × STAGE_VALUE
        │    - Returns TCOST and return code to QMASBATCH
        │
        ▼
  DB2 for i — RWYNN01.DEFECTPF
  - INSERT new records
  - UPDATE existing records (duplicate key handling)
  - COMMIT on completion
        │
        ▼
  Control Report (RPTOUT spool)
  - SEQ / DEFID / STATUS / MESSAGE per record
  - Total Processed / Loaded / Rejected / Financial Value
        │
        ▼
  QMASINT (Interactive Program)
  ┌─────────────────────────────────────┐
  │  Screen 1: Filter Menu              │
  │  - Production Line / Severity /     │
  │    Detection Stage filters          │
  └──────────────┬──────────────────────┘
                 │
  ┌──────────────▼──────────────────────┐
  │  Screen 2: Defect List (Subfile)    │
  │  - Scrollable filtered results      │
  │  - Option 5 = drill down            │
  └──────────────┬──────────────────────┘
                 │
  ┌──────────────▼──────────────────────┐
  │  Screen 3: Detail View              │
  │  - Full record display              │
  │  - CRITICAL ESCAPE warning          │
  │    (SEV=1 + STAGE=FG)               │
  └─────────────────────────────────────┘
```

---

## 🗄 Database Schema

### RWYNN01.DEFECTPF

| Column | Type | Description |
|---|---|---|
| DEFID | CHAR(8) | Defect ID — primary key |
| LINE | CHAR(4) | Production line e.g. LN01 |
| PARTNO | CHAR(10) | Part number |
| TYPECD | DECIMAL(2,0) | Defect type code |
| TYPEDESC | CHAR(30) | Defect type description |
| SEV | DECIMAL(1,0) | Severity: 1=Critical, 2=Major, 3=Minor |
| BCOST | DECIMAL(9,2) | Base cost of defect |
| STAGE | CHAR(2) | Detection stage: RW, IP, or FG |
| RWK | CHAR(1) | Rework flag: Y or N |
| TCOST | DECIMAL(11,2) | Total cost = BCOST × SEV multiplier × STAGE multiplier |

### QRSC.SEVERITY (Lookup)
| Column | Description |
|---|---|
| SEVERITY_CODE | 1, 2, or 3 |
| SEVERITY_VALUE | Multiplier applied to BCOST |

### QRSC.DETSTAGE (Lookup)
| Column | Description |
|---|---|
| STAGE_CODE | RW, IP, or FG |
| STAGE_VALUE | Multiplier applied to BCOST |

---

## 🚀 How to Run

### Prerequisites
- IBM i V7R5 with library RWYNN01
- DEFECTPF journaled for SQL write operations
- CSVIN physical file populated in QRSC library
- QRSC.SEVERITY and QRSC.DETSTAGE lookup tables populated

### Compile Order
```
1. CRTDSPF   FILE(RWYNN01/QMASDSPF) SRCFILE(RWYNN01/QDDSSRC)
2. CRTSQLCBL PGM(RWYNN01/QMASTCOST) SRCFILE(RWYNN01/QCBLLESRC)
3. CRTSQLCBL PGM(RWYNN01/QMASBATCH) SRCFILE(RWYNN01/QCBLLESRC)
4. CRTSQLCBL PGM(RWYNN01/QMASINT)   SRCFILE(RWYNN01/QCBLLESRC)
5. CRTCLPGM  PGM(RWYNN01/CLWRAP)    SRCFILE(RWYNN01/QCLSRC)
```

### Run the Batch Job
```
SBMJOB CMD(CALL PGM(RWYNN01/CLWRAP)) JOB(BATCHRUN1)
```

### Schedule Nightly Runs
```
ADDJOBSCDE JOB(BATCHRUN1)
           CMD(CALL PGM(RWYNN01/CLWRAP))
           FRQ(*WEEKLY)
           SCDDAY(*MON *TUE *WED *THU *FRI)
           SCDTIME(020000)
```

### Launch the Interactive Program
```
CALL PGM(RWYNN01/QMASINT)
```

### View Loaded Data
```sql
SELECT * FROM RWYNN01.DEFECTPF as a
```

---

## 💡 Key Technical Concepts Demonstrated

- **Embedded SQL in ILE COBOL** — `EXEC SQL INSERT`, `UPDATE`, `SELECT INTO` with host variables and SQLCA error handling
- **Subfile programming** — DDS `SFL`/`SFLCTL` with clear/load/display cycle, `READ SUBFILE NEXT MODIFIED RECORD` for option handling
- **Subprogram CALL/USING** — linkage section parameter passing between batch and subprogram
- **UNSTRING** — comma-delimited CSV parsing into individual fields
- **Upsert pattern** — INSERT attempted first, `-803` duplicate key triggers UPDATE
- **CL job automation** — `OVRDBF`, `ADDLIBLE`, `SBMJOB`, `ADDJOBSCDE`, `MONMSG` error handling
- **DDS indicator programming** — `CA`/`CF` function keys, conditional display attributes (`DSPATR(RI BL)`), `COLOR(RED)` for Critical Escape warning
- **DB2 lookup tables** — multiplier values fetched at runtime from QRSC schema

---

## 👩‍💻 Author

**Robin Wynn**
NeXTLegacy COBOL Program — Cohort 1
Mississippi Coding Academies

---

## 📄 Documentation

See [`docs/QMAS_RunSheet.pdf`](docs/QMAS-RunSheet.pdf) for the full operational run sheet including compile instructions, scheduling, screen navigation, and troubleshooting.
