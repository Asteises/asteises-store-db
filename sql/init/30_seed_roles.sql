INSERT INTO role(id, code, title) VALUES
                                      (uuid_generate_v4(), 'ROLE_ADMIN', 'Administrator'),
                                      (uuid_generate_v4(), 'ROLE_MANAGER', 'Manager'),
                                      (uuid_generate_v4(), 'ROLE_USER', 'User')
ON CONFLICT (code) DO NOTHING;

-- Базовые права для редактора карточек (можно расширять)
INSERT INTO permission(id, code, title) VALUES
                                            (uuid_generate_v4(), 'product:read',  'Read products'),
                                            (uuid_generate_v4(), 'product:write', 'Modify products'),
                                            (uuid_generate_v4(), 'media:write',   'Upload/delete media')
ON CONFLICT (code) DO NOTHING;

-- Примапим права к ролям ADMIN и MANAGER
WITH p AS (
    SELECT id, code FROM permission WHERE code IN ('product:read','product:write','media:write')
),
     r AS (
         SELECT id, code FROM role WHERE code IN ('ROLE_ADMIN','ROLE_MANAGER')
     )
INSERT INTO role_permission(role_id, permission_id)
SELECT r.id, p.id FROM r CROSS JOIN p
ON CONFLICT DO NOTHING;
