-- Seed mutual-like data for demo
-- These swipe rows represent employees who have "already liked" Alice.
-- When Alice swipes right on any of them, the backend detects a mutual match
-- and returns the match overlay immediately — enabling instant demo of the match flow.

-- Ben likes Alice (when Alice likes Ben back → instant match demo)
INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
SELECT b.id, a.id, true, NOW() - INTERVAL '1 hour'
FROM employee b, employee a
WHERE b.email = 'ben.martinez@deloitte.demo'
  AND a.email = 'alice.chen@deloitte.demo';

-- Chloe likes Alice
INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
SELECT c.id, a.id, true, NOW() - INTERVAL '2 hours'
FROM employee c, employee a
WHERE c.email = 'chloe.patel@deloitte.demo'
  AND a.email = 'alice.chen@deloitte.demo';

-- Emily likes Alice
INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
SELECT e.id, a.id, true, NOW() - INTERVAL '3 hours'
FROM employee e, employee a
WHERE e.email = 'emily.zhang@deloitte.demo'
  AND a.email = 'alice.chen@deloitte.demo';

-- Daniel likes Alice
INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
SELECT d.id, a.id, true, NOW() - INTERVAL '4 hours'
FROM employee d, employee a
WHERE d.email = 'daniel.kim@deloitte.demo'
  AND a.email = 'alice.chen@deloitte.demo';

-- Alice likes Frank (Frank hasn't liked Alice → no match, demonstrates privacy guardrail:
-- Frank's stack looks identical to everyone else's from Alice's perspective)
INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
SELECT a.id, f.id, true, NOW() - INTERVAL '30 minutes'
FROM employee a, employee f
WHERE a.email = 'alice.chen@deloitte.demo'
  AND f.email = 'frank.wilson@deloitte.demo';

