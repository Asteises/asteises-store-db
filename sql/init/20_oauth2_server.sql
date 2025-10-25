-- Зарегистрированные OAuth2/OIDC клиенты
CREATE TABLE IF NOT EXISTS oauth2_registered_client (
                                                        id                              VARCHAR(100) PRIMARY KEY,
                                                        client_id                       VARCHAR(100) NOT NULL,
                                                        client_id_issued_at             TIMESTAMPTZ NOT NULL,
                                                        client_secret                   VARCHAR(200),
                                                        client_secret_expires_at        TIMESTAMPTZ,
                                                        client_name                     VARCHAR(200) NOT NULL,
                                                        client_authentication_methods   TEXT NOT NULL,
                                                        authorization_grant_types       TEXT NOT NULL,
                                                        redirect_uris                   TEXT,
                                                        post_logout_redirect_uris       TEXT,
                                                        scopes                          TEXT NOT NULL,
                                                        client_settings                 TEXT NOT NULL,
                                                        token_settings                  TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_oauth2_registered_client_client_id
    ON oauth2_registered_client (client_id);

-- Авторизации/токены (access/refresh/code/device/oidc)
CREATE TABLE IF NOT EXISTS oauth2_authorization (
                                                    id                              VARCHAR(100) PRIMARY KEY,
                                                    registered_client_id            VARCHAR(100) NOT NULL,
                                                    principal_name                  VARCHAR(200) NOT NULL,
                                                    authorization_grant_type        VARCHAR(100) NOT NULL,
                                                    authorized_scopes               TEXT,
                                                    attributes                      TEXT,
                                                    state                           TEXT,
                                                    authorization_code_value        BYTEA,
                                                    authorization_code_issued_at    TIMESTAMPTZ,
                                                    authorization_code_expires_at   TIMESTAMPTZ,
                                                    authorization_code_metadata     TEXT,
                                                    access_token_value              BYTEA,
                                                    access_token_issued_at          TIMESTAMPTZ,
                                                    access_token_expires_at         TIMESTAMPTZ,
                                                    access_token_metadata           TEXT,
                                                    access_token_type               VARCHAR(100),
                                                    access_token_scopes             TEXT,
                                                    oidc_id_token_value             BYTEA,
                                                    oidc_id_token_issued_at         TIMESTAMPTZ,
                                                    oidc_id_token_expires_at        TIMESTAMPTZ,
                                                    oidc_id_token_metadata          TEXT,
                                                    refresh_token_value             BYTEA,
                                                    refresh_token_issued_at         TIMESTAMPTZ,
                                                    refresh_token_expires_at        TIMESTAMPTZ,
                                                    refresh_token_metadata          TEXT,
                                                    user_code_value                 BYTEA,
                                                    user_code_issued_at             TIMESTAMPTZ,
                                                    user_code_expires_at            TIMESTAMPTZ,
                                                    user_code_metadata              TEXT,
                                                    device_code_value               BYTEA,
                                                    device_code_issued_at           TIMESTAMPTZ,
                                                    device_code_expires_at          TIMESTAMPTZ,
                                                    device_code_metadata            TEXT
);
CREATE INDEX IF NOT EXISTS idx_oauth2_authorization_principal
    ON oauth2_authorization (principal_name);

-- Согласия пользователя клиенту
CREATE TABLE IF NOT EXISTS oauth2_authorization_consent (
                                                            registered_client_id    VARCHAR(100) NOT NULL,
                                                            principal_name          VARCHAR(200) NOT NULL,
                                                            authorities             TEXT NOT NULL,
                                                            PRIMARY KEY (registered_client_id, principal_name)
);
