-- Centro de Jogos - esquema inicial
-- Importe este ficheiro na base de dados utilizada pelo seu servidor FiveM.

CREATE TABLE IF NOT EXISTS `cj_companies` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `balance` BIGINT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cj_companies_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cj_company_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT UNSIGNED NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `grade` VARCHAR(50) NOT NULL DEFAULT 'employee',
    `hired_by` VARCHAR(50) DEFAULT NULL,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cj_employee_company` (`company_id`, `citizenid`),
    KEY `idx_cj_employee_citizenid` (`citizenid`),
    CONSTRAINT `fk_cj_employee_company` FOREIGN KEY (`company_id`) REFERENCES `cj_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cj_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT UNSIGNED NOT NULL,
    `citizenid` VARCHAR(50) DEFAULT NULL,
    `type` VARCHAR(50) NOT NULL,
    `amount` BIGINT NOT NULL,
    `metadata` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cj_transaction_company_date` (`company_id`, `created_at`),
    KEY `idx_cj_transaction_citizenid` (`citizenid`),
    CONSTRAINT `fk_cj_transaction_company` FOREIGN KEY (`company_id`) REFERENCES `cj_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cj_draws` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(100) NOT NULL,
    `ticket_price` INT UNSIGNED NOT NULL,
    `prize_amount` BIGINT NOT NULL DEFAULT 0,
    `status` ENUM('draft', 'open', 'drawn', 'cancelled') NOT NULL DEFAULT 'draft',
    `winner_citizenid` VARCHAR(50) DEFAULT NULL,
    `draw_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_cj_draw_company_status` (`company_id`, `status`),
    CONSTRAINT `fk_cj_draw_company` FOREIGN KEY (`company_id`) REFERENCES `cj_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cj_draw_tickets` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `draw_id` INT UNSIGNED NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `ticket_number` VARCHAR(36) NOT NULL,
    `purchased_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cj_ticket_number` (`ticket_number`),
    KEY `idx_cj_ticket_draw_citizen` (`draw_id`, `citizenid`),
    CONSTRAINT `fk_cj_ticket_draw` FOREIGN KEY (`draw_id`) REFERENCES `cj_draws` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cj_jackpots` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `amount` BIGINT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cj_jackpot_company_name` (`company_id`, `name`),
    CONSTRAINT `fk_cj_jackpot_company` FOREIGN KEY (`company_id`) REFERENCES `cj_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `cj_companies` (`name`, `balance`) VALUES ('Centro de Jogos', 0);
