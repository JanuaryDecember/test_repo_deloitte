-- Demo password for all employees: password123
-- BCrypt hash (cost 10): $2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm

INSERT INTO employee (email, password_hash, first_name, last_name, service_line, role_family, contact_info) VALUES
    ('alice.chen@deloitte.demo',      '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Alice',    'Chen',      'Consulting',          'Senior Consultant', '@alice.chen'),
    ('ben.martinez@deloitte.demo',    '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Ben',      'Martinez',  'Consulting',          'Manager',           '@ben.martinez'),
    ('chloe.patel@deloitte.demo',     '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Chloe',    'Patel',     'Consulting',          'Consultant',        '@chloe.patel'),
    ('daniel.kim@deloitte.demo',      '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Daniel',   'Kim',       'Consulting',          'Analyst',           '@daniel.kim'),
    ('emily.zhang@deloitte.demo',     '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Emily',    'Zhang',     'Consulting',          'Senior Consultant', '@emily.zhang'),
    ('frank.wilson@deloitte.demo',    '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Frank',    'Wilson',    'Audit & Assurance',   'Manager',           '@frank.wilson'),
    ('grace.lee@deloitte.demo',       '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Grace',    'Lee',       'Audit & Assurance',   'Senior Consultant', '@grace.lee'),
    ('henry.brown@deloitte.demo',     '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Henry',    'Brown',     'Audit & Assurance',   'Consultant',        '@henry.brown'),
    ('isabella.nguyen@deloitte.demo', '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Isabella', 'Nguyen',    'Audit & Assurance',   'Analyst',           '@isabella.nguyen'),
    ('james.taylor@deloitte.demo',    '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'James',    'Taylor',    'Audit & Assurance',   'Senior Consultant', '@james.taylor'),
    ('kate.anderson@deloitte.demo',   '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Kate',     'Anderson',  'Tax & Legal',         'Manager',           '@kate.anderson'),
    ('liam.thomas@deloitte.demo',     '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Liam',     'Thomas',    'Tax & Legal',         'Senior Consultant', '@liam.thomas'),
    ('maya.jackson@deloitte.demo',    '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Maya',     'Jackson',   'Tax & Legal',         'Consultant',        '@maya.jackson'),
    ('noah.white@deloitte.demo',      '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Noah',     'White',     'Tax & Legal',         'Analyst',           '@noah.white'),
    ('olivia.harris@deloitte.demo',   '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Olivia',   'Harris',    'Tax & Legal',         'Senior Consultant', '@olivia.harris'),
    ('peter.robinson@deloitte.demo',  '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Peter',    'Robinson',  'Risk Advisory',       'Manager',           '@peter.robinson'),
    ('quinn.davis@deloitte.demo',     '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Quinn',    'Davis',     'Risk Advisory',       'Senior Consultant', '@quinn.davis'),
    ('rachel.miller@deloitte.demo',   '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Rachel',   'Miller',    'Risk Advisory',       'Consultant',        '@rachel.miller'),
    ('sam.wilson@deloitte.demo',      '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Sam',      'Wilson',    'Risk Advisory',       'Analyst',           '@sam.wilson'),
    ('tara.moore@deloitte.demo',      '$2b$10$cR6oqvYhnVSEhE7xtgZ.zelCBwyFHqclwOaePbyJMu/uZPlN2Odlm', 'Tara',     'Moore',     'Risk Advisory',       'Senior Consultant', '@tara.moore');

-- ---------------------------------------------------------------------------
-- Employee interests
-- Cluster A (Consulting): Machine Learning, Startups, Design Thinking core
-- Cluster B (Audit):      Reading, Board Games, Fitness core
-- Cluster C (Tax/Legal):  Sustainability, Volunteering, Music core
-- Cluster D (Risk):       Gaming, Photography, Hiking core
-- Cross-cluster glue:     Travel, Public Speaking, Cooking, Fitness spread
-- ---------------------------------------------------------------------------

-- alice.chen: Machine Learning, Travel, Startups, Design Thinking, Photography
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'alice.chen@deloitte.demo'
  AND i.name IN ('Machine Learning', 'Travel', 'Startups', 'Design Thinking', 'Photography');

-- ben.martinez: Machine Learning, Startups, Public Speaking, Fitness, Travel
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'ben.martinez@deloitte.demo'
  AND i.name IN ('Machine Learning', 'Startups', 'Public Speaking', 'Fitness', 'Travel');

-- chloe.patel: Machine Learning, Design Thinking, Cooking, Music, Startups, Photography
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'chloe.patel@deloitte.demo'
  AND i.name IN ('Machine Learning', 'Design Thinking', 'Cooking', 'Music', 'Startups', 'Photography');

-- daniel.kim: Machine Learning, Gaming, Startups, Travel, Fitness
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'daniel.kim@deloitte.demo'
  AND i.name IN ('Machine Learning', 'Gaming', 'Startups', 'Travel', 'Fitness');

-- emily.zhang: Design Thinking, Photography, Music, Travel, Sustainability, Startups
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'emily.zhang@deloitte.demo'
  AND i.name IN ('Design Thinking', 'Photography', 'Music', 'Travel', 'Sustainability', 'Startups');

-- frank.wilson: Reading, Board Games, Fitness, Travel, Music
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'frank.wilson@deloitte.demo'
  AND i.name IN ('Reading', 'Board Games', 'Fitness', 'Travel', 'Music');

-- grace.lee: Reading, Board Games, Cooking, Sustainability, Music
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'grace.lee@deloitte.demo'
  AND i.name IN ('Reading', 'Board Games', 'Cooking', 'Sustainability', 'Music');

-- henry.brown: Fitness, Reading, Hiking, Board Games, Photography
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'henry.brown@deloitte.demo'
  AND i.name IN ('Fitness', 'Reading', 'Hiking', 'Board Games', 'Photography');

-- isabella.nguyen: Reading, Volunteering, Music, Sustainability, Cooking
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'isabella.nguyen@deloitte.demo'
  AND i.name IN ('Reading', 'Volunteering', 'Music', 'Sustainability', 'Cooking');

-- james.taylor: Reading, Fitness, Board Games, Travel, Photography
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'james.taylor@deloitte.demo'
  AND i.name IN ('Reading', 'Fitness', 'Board Games', 'Travel', 'Photography');

-- kate.anderson: Sustainability, Volunteering, Music, Public Speaking, Design Thinking
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'kate.anderson@deloitte.demo'
  AND i.name IN ('Sustainability', 'Volunteering', 'Music', 'Public Speaking', 'Design Thinking');

-- liam.thomas: Sustainability, Volunteering, Hiking, Reading, Cooking
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'liam.thomas@deloitte.demo'
  AND i.name IN ('Sustainability', 'Volunteering', 'Hiking', 'Reading', 'Cooking');

-- maya.jackson: Volunteering, Music, Public Speaking, Photography, Sustainability
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'maya.jackson@deloitte.demo'
  AND i.name IN ('Volunteering', 'Music', 'Public Speaking', 'Photography', 'Sustainability');

-- noah.white: Volunteering, Hiking, Cooking, Board Games, Fitness
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'noah.white@deloitte.demo'
  AND i.name IN ('Volunteering', 'Hiking', 'Cooking', 'Board Games', 'Fitness');

-- olivia.harris: Sustainability, Music, Design Thinking, Travel, Photography
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'olivia.harris@deloitte.demo'
  AND i.name IN ('Sustainability', 'Music', 'Design Thinking', 'Travel', 'Photography');

-- peter.robinson: Gaming, Photography, Hiking, Fitness, Travel
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'peter.robinson@deloitte.demo'
  AND i.name IN ('Gaming', 'Photography', 'Hiking', 'Fitness', 'Travel');

-- quinn.davis: Gaming, Hiking, Photography, Music, Board Games
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'quinn.davis@deloitte.demo'
  AND i.name IN ('Gaming', 'Hiking', 'Photography', 'Music', 'Board Games');

-- rachel.miller: Gaming, Photography, Hiking, Cooking, Travel
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'rachel.miller@deloitte.demo'
  AND i.name IN ('Gaming', 'Photography', 'Hiking', 'Cooking', 'Travel');

-- sam.wilson: Gaming, Fitness, Hiking, Photography, Board Games
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'sam.wilson@deloitte.demo'
  AND i.name IN ('Gaming', 'Fitness', 'Hiking', 'Photography', 'Board Games');

-- tara.moore: Gaming, Travel, Music, Design Thinking, Photography, Startups
INSERT INTO employee_interest (employee_id, interest_id)
SELECT e.id, i.id FROM employee e, interest i
WHERE e.email = 'tara.moore@deloitte.demo'
  AND i.name IN ('Gaming', 'Travel', 'Music', 'Design Thinking', 'Photography', 'Startups');

-- ---------------------------------------------------------------------------
-- Employee competencies
-- Cluster A (Consulting): Java, Python, AI/ML Engineering, Strategy Consulting core
-- Cluster B (Audit):      Financial Modeling, Risk Assessment, Data Analytics core
-- Cluster C (Tax/Legal):  Change Management, Stakeholder Management core
-- Cluster D (Risk):       Cybersecurity, DevOps, Cloud Architecture core
-- Cross-cluster glue:     Project Management, Agile Coaching, Data Analytics spread
-- ---------------------------------------------------------------------------

-- alice.chen: Java, Python, AI/ML Engineering, Strategy Consulting, Agile Coaching
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'alice.chen@deloitte.demo'
  AND c.name IN ('Java', 'Python', 'AI/ML Engineering', 'Strategy Consulting', 'Agile Coaching');

-- ben.martinez: Python, AI/ML Engineering, Strategy Consulting, Stakeholder Management, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'ben.martinez@deloitte.demo'
  AND c.name IN ('Python', 'AI/ML Engineering', 'Strategy Consulting', 'Stakeholder Management', 'Project Management');

-- chloe.patel: Java, Python, AI/ML Engineering, UX Design, Agile Coaching
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'chloe.patel@deloitte.demo'
  AND c.name IN ('Java', 'Python', 'AI/ML Engineering', 'UX Design', 'Agile Coaching');

-- daniel.kim: Java, Python, Data Analytics, Cloud Architecture, DevOps
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'daniel.kim@deloitte.demo'
  AND c.name IN ('Java', 'Python', 'Data Analytics', 'Cloud Architecture', 'DevOps');

-- emily.zhang: UX Design, Strategy Consulting, Agile Coaching, Project Management, Stakeholder Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'emily.zhang@deloitte.demo'
  AND c.name IN ('UX Design', 'Strategy Consulting', 'Agile Coaching', 'Project Management', 'Stakeholder Management');

-- frank.wilson: Financial Modeling, Risk Assessment, Data Analytics, Stakeholder Management, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'frank.wilson@deloitte.demo'
  AND c.name IN ('Financial Modeling', 'Risk Assessment', 'Data Analytics', 'Stakeholder Management', 'Project Management');

-- grace.lee: Financial Modeling, Data Analytics, Risk Assessment, Change Management, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'grace.lee@deloitte.demo'
  AND c.name IN ('Financial Modeling', 'Data Analytics', 'Risk Assessment', 'Change Management', 'Project Management');

-- henry.brown: Financial Modeling, Risk Assessment, Data Analytics, Agile Coaching
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'henry.brown@deloitte.demo'
  AND c.name IN ('Financial Modeling', 'Risk Assessment', 'Data Analytics', 'Agile Coaching');

-- isabella.nguyen: Data Analytics, Financial Modeling, Change Management, Stakeholder Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'isabella.nguyen@deloitte.demo'
  AND c.name IN ('Data Analytics', 'Financial Modeling', 'Change Management', 'Stakeholder Management');

-- james.taylor: Financial Modeling, Risk Assessment, Strategy Consulting, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'james.taylor@deloitte.demo'
  AND c.name IN ('Financial Modeling', 'Risk Assessment', 'Strategy Consulting', 'Project Management');

-- kate.anderson: Change Management, Stakeholder Management, Strategy Consulting, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'kate.anderson@deloitte.demo'
  AND c.name IN ('Change Management', 'Stakeholder Management', 'Strategy Consulting', 'Project Management');

-- liam.thomas: Change Management, Stakeholder Management, Risk Assessment, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'liam.thomas@deloitte.demo'
  AND c.name IN ('Change Management', 'Stakeholder Management', 'Risk Assessment', 'Project Management');

-- maya.jackson: Change Management, Stakeholder Management, UX Design, Strategy Consulting
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'maya.jackson@deloitte.demo'
  AND c.name IN ('Change Management', 'Stakeholder Management', 'UX Design', 'Strategy Consulting');

-- noah.white: Project Management, Agile Coaching, Change Management, Risk Assessment
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'noah.white@deloitte.demo'
  AND c.name IN ('Project Management', 'Agile Coaching', 'Change Management', 'Risk Assessment');

-- olivia.harris: Stakeholder Management, Strategy Consulting, UX Design, Change Management, Project Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'olivia.harris@deloitte.demo'
  AND c.name IN ('Stakeholder Management', 'Strategy Consulting', 'UX Design', 'Change Management', 'Project Management');

-- peter.robinson: Cybersecurity, DevOps, Cloud Architecture, Risk Assessment, Stakeholder Management
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'peter.robinson@deloitte.demo'
  AND c.name IN ('Cybersecurity', 'DevOps', 'Cloud Architecture', 'Risk Assessment', 'Stakeholder Management');

-- quinn.davis: Cybersecurity, DevOps, Cloud Architecture, Java, Data Analytics
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'quinn.davis@deloitte.demo'
  AND c.name IN ('Cybersecurity', 'DevOps', 'Cloud Architecture', 'Java', 'Data Analytics');

-- rachel.miller: Cybersecurity, DevOps, Python, Cloud Architecture, Risk Assessment
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'rachel.miller@deloitte.demo'
  AND c.name IN ('Cybersecurity', 'DevOps', 'Python', 'Cloud Architecture', 'Risk Assessment');

-- sam.wilson: Cybersecurity, Cloud Architecture, Data Analytics, DevOps
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'sam.wilson@deloitte.demo'
  AND c.name IN ('Cybersecurity', 'Cloud Architecture', 'Data Analytics', 'DevOps');

-- tara.moore: Cybersecurity, AI/ML Engineering, DevOps, Project Management, UX Design
INSERT INTO employee_competency (employee_id, competency_id)
SELECT e.id, c.id FROM employee e, competency c
WHERE e.email = 'tara.moore@deloitte.demo'
  AND c.name IN ('Cybersecurity', 'AI/ML Engineering', 'DevOps', 'Project Management', 'UX Design');

