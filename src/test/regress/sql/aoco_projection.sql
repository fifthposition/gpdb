-- Tests to validate column projection for various operations

-- Tests for COPY TO (SELECT <...> FROM <aoco_table>) TO ..
CREATE TABLE aoco(i int, j bigint, k int) USING ao_column;
INSERT INTO aoco SELECT 0, i, 1 FROM generate_series(1, 100000) i;
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads all blocks in the table as all columns are specified.
COPY (SELECT * FROM aoco) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads all blocks in the table as all columns are specified.
COPY (SELECT i,j,k FROM aoco) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads blocks only for cols: i int, j bigint
COPY (SELECT i,j FROM aoco) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads blocks only for cols: i int
COPY (SELECT i FROM aoco) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Tests for COPY <aoco_table> (<col_list>) TO ..

-- Reads all blocks in the table as all columns are implicitly specified.
COPY aoco TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads all blocks in the table as all columns are specified.
COPY aoco (i,j,k) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads blocks only for cols: i int, j bigint
COPY aoco (i,j) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Reads blocks only for cols: i int
COPY aoco (i) TO '/dev/null';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- When calling ATTACH PARTITION on a table T to a root R or subroot SR inside a partition hierarchy,
-- T needs to be scanned to validate C (the partition constraint of R combined with the
-- partition bound clause in the ATTACH command). If T is an AOCO table, we only need to scan
-- columns referenced in C.

-- When a sibling DEFAULT PARTITION D is present under an R/SR in a partition hierarchy
-- and we are attaching a table T, then D's partition bound C will be updated, taking into
-- account the partition bound clause in the ATTACH command. D will be scanned against
-- the proposed new bound C' for validation. If a row is found that doesn't match C',
-- an ERROR will be thrown. If D is an AOCO table, only columns referenced in C' need
-- to be scanned. If D is a partition root, then all of its children will also need to be
-- scanned to validate C'.

-- Since EXCHANGE PARTITION calls ATTACH PARTITION internally, these cases will also arise and the same rules and logic will apply.

-- The following tests validate blocks scanned by running each DDL several times, first recording total
-- blocks scanned for the command, then recording blocks scanned for each table (whose sum should be equal the total).
-- This is done as we can't inject the same fault for different tables simultaneously.

CREATE table alter_attach(i int, j bigint, k int) USING ao_column
  DISTRIBUTED BY (i)
  PARTITION BY RANGE (j);

CREATE TABLE alter_attach_t1(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i);
CREATE TABLE alter_attach_t2(i int, k int, j bigint) USING ao_column DISTRIBUTED BY (i); -- modified column layout
CREATE TABLE alter_attach_t3(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i);
CREATE TABLE alter_attach_t4(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i);
CREATE TABLE alter_exchange_t5(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i);
CREATE TABLE alter_exchange_t6(i int, k int, j bigint) USING ao_column DISTRIBUTED BY (i); -- modified column layout
CREATE TABLE alter_attach_d1(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i);
CREATE TABLE alter_attach_d2(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i);
CREATE TABLE alter_attach_sr(i int, j bigint, k int) USING ao_column DISTRIBUTED BY (i) PARTITION BY RANGE (k);

INSERT INTO alter_attach_t1 SELECT 0,1,0 FROM generate_series(1,100000);
INSERT INTO alter_attach_t2 SELECT 0,0,2 FROM generate_series(1,100000);
INSERT INTO alter_attach_t3 SELECT 0,3,1 FROM generate_series(1,100000);
INSERT INTO alter_attach_t4 SELECT 0,3,2 FROM generate_series(1,100000);
INSERT INTO alter_attach_d1 SELECT 0,0,0 FROM generate_series(1,100000);
INSERT INTO alter_attach_d2 SELECT 0,3,0 FROM generate_series(1,100000);
INSERT INTO alter_exchange_t5 SELECT 0,1,0 FROM generate_series(1,100000);
INSERT INTO alter_exchange_t6 SELECT 0,1,3 FROM generate_series(1,100000);

-- Attach table T1 to R, T1 (j) will be scanned.
--     R
--    /
--   T1
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_t1 FOR VALUES FROM (1) TO (2);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_t1;

-- Validate T1 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t1', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_t1 FOR VALUES FROM (1) TO (2);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Attach default D1 to root, D1 (j) will be scanned.
--     R
--    / \
--   T1  D1
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_d1 DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_d1;

-- Validate D1 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d1', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_d1 DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Attach table T2 to root in presence of D1, columns T2 (j) and D1 (j) will be scanned.
--      R
--    / | \
--   T1 D1 T2
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_t2 FOR VALUES FROM (2) TO (3);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_t2;

-- Validate T2 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t2', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_t2 FOR VALUES FROM (2) TO (3);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_t2;

-- Validate D1 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d1', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_t2 FOR VALUES FROM (2) TO (3);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Attach subroot SR1 to R, column D1 (j) will be scanned.
--       R
--    / | | \
--  T1 D1 T2 SR1
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_sr FOR VALUES FROM (3) TO (4);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_sr;

-- Validate D1 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d1', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_sr FOR VALUES FROM (3) TO (4);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Attach table T3 to SR1, columns T3 (j, k) will be scanned
--       R
--    / | | \
--  T1 D1 T2 SR1
--            |
--            T3
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_t3 FOR VALUES FROM (1) TO (2);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr DETACH PARTITION alter_attach_t3;

-- Validate T3 (j, k) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t3', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_t3 FOR VALUES FROM (1) TO (2);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Attach default D2 to SR1, D2 (j, k) will be scanned.
--       R
--    / | | \
--  T1 D1 T2 SR1
--           / \
--          T3  D2
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_d2 DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr DETACH PARTITION alter_attach_d2;

-- Validate D2 (j,k) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d2', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_d2 DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Attach table T4 to SR1 in presence of default D2, T4 (j,k) and D2 (k) will be scanned
--       R
--    / | | \
--  T1 D1 T2 SR1
--          / | \ 
--         T3 D2 T4
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_t4 FOR VALUES FROM (2) TO (3);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr DETACH PARTITION alter_attach_t4;

-- Validate D2 (k) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d2', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_t4 FOR VALUES FROM (2) TO (3);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr DETACH PARTITION alter_attach_t4;

-- Validate T4 (j, k) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t4', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr ATTACH PARTITION alter_attach_t4 FOR VALUES FROM (2) TO (3);

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';


ALTER TABLE alter_attach DETACH PARTITION alter_attach_d1;
ALTER TABLE alter_attach DETACH PARTITION alter_attach_sr;

-- Attach R2 to R1 as a default partition, T3 (j), T4 (j) and D2 (j) will be scanned
--      R1
--    / | \
--  T1 T2  R2 (D)
--        / | \
--       T3 D2 T4
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_sr DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_sr;

-- Validate T3 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t3', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_sr DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_sr;

-- Validate T4 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t4', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_sr DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach DETACH PARTITION alter_attach_sr;

-- Validate D2 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d2', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach ATTACH PARTITION alter_attach_sr DEFAULT;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Since EXCHANGE PARTITION calls ATTACH PARTITION internally, the same rules and logic will apply.
-- Exchange T1 with T5, T5 (j), T3 (j), T4 (j), D2 (j) will be scanned
--         R
--       / | \
-- T5<->T1 T2  R2 (D)
--              / | \
--             T3 D2 T4
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, 101, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t5;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Validate T5 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_exchange_t5', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t5;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Validate T3 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t3', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t5;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Validate T4 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_t4', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t5;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Validate D2 (j) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d2', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t5;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Exchange T3 with T6, T6 (j,k) and D2 (k) will be scanned
--    R
--  / | \
-- T5 T2  R2 (D)
--        /  | \
--   T6<->T3 D2 T4
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', '', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t6;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Validate T6 (j,k) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_exchange_t6', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t6;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

-- Validate D2 (k) scanned
SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'skip', '', '', 'alter_attach_d2', 1, -1, 0, dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

ALTER TABLE alter_attach_sr EXCHANGE PARTITION FOR (1) WITH TABLE alter_exchange_t6;

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'status', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';

SELECT gp_inject_fault('AppendOnlyStorageRead_ReadNextBlock_success', 'reset', dbid)
    FROM gp_segment_configuration WHERE content = 1 AND role = 'p';
