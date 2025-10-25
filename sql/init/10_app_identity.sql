-- Пользователи админки
CREATE TABLE IF NOT EXISTS app_user (
                                        id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                        email         CITEXT UNIQUE NOT NULL,
                                        display_name  TEXT NOT NULL,
                                        password_hash TEXT NOT NULL,
                                        is_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
                                        is_locked     BOOLEAN NOT NULL DEFAULT FALSE,
                                        created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                                        created_by    TEXT,
                                        updated_at    TIMESTAMPTZ,
                                        updated_by    TEXT
);

-- Роли (ADMIN, MANAGER, USER ...)
CREATE TABLE IF NOT EXISTS role (
                                    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                    code        TEXT UNIQUE NOT NULL, -- ROLE_ADMIN, ROLE_MANAGER, ROLE_USER
                                    title       TEXT NOT NULL,
                                    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Permissions в виде строк (product:read, product:write ...)
CREATE TABLE IF NOT EXISTS permission (
                                          id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                          code        TEXT UNIQUE NOT NULL,
                                          title       TEXT NOT NULL
);

-- Маппинги
CREATE TABLE IF NOT EXISTS user_role (
                                         user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
                                         role_id UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
                                         PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS role_permission (
                                               role_id UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
                                               permission_id UUID NOT NULL REFERENCES permission(id) ON DELETE CASCADE,
                                               PRIMARY KEY (role_id, permission_id)
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_app_user_email ON app_user (email);
