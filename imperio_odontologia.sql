phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 22/10/2024 às 16:21
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `imperio_odontologia`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `appointments`
--

CREATE TABLE `appointments` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `service` varchar(100) NOT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` time NOT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('Agendado','Completo','Cancelado') DEFAULT 'Agendado',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `patient_address` varchar(255) NOT NULL,
  `patient_phone` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `services`
--

CREATE TABLE `services` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `services`
--

INSERT INTO `services` (`id`, `name`, `description`, `price`) VALUES
(1, 'Limpeza', 'Limpeza dentária completa para remoção de tártaro e placa', 150.00),
(2, 'Clareamento Dental', 'Clareamento para um sorriso mais branco e brilhante', 400.00),
(3, 'Ortodontia', 'Tratamento ortodôntico para corrigir a posição dos dentes', 1200.00),
(4, 'Implante', 'Implante dentário para substituição de dentes perdidos', 3000.00),
(5, 'Consulta de Rotina', 'Avaliação odontológica para prevenção e manutenção da saúde bucal', 100.00);

-- --------------------------------------------------------

--
-- Estrutura para tabela `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `is_admin` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL,
  `status` enum('active','inactive','suspended') DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `password`, `is_admin`, `created_at`, `last_login`, `status`) VALUES
(2, 'Romeu', 'romeu0016@gmail.com', '$2y$10$WwXp8P.6m4Hd/HQR5YRPT.4esqLt5SskqtZqdKjx2fg.JxeWPSRpG', 1, '2024-10-14 17:16:54', '2024-10-22 14:14:20', 'active'),
(3, 'Romeu', 'Romeu1@gmail.com', '$2y$10$vwfRW.4Vz0zntIKXJuzmueRjptb03E4KxFvf/cOMGX2tH8eIPiZqq', 0, '2024-10-14 17:37:37', '2024-10-16 14:57:42', 'active');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Índices de tabela `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `appointments`
--
ALTER TABLE `appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de tabela `services`
--
ALTER TABLE `services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de tabela `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

-- =========================================================
-- TRIGGERS E PROCEDURES ADICIONADOS
-- =========================================================

DELIMITER $$

-- Trigger: normalizar email e nome antes de inserir usuário
CREATE TRIGGER `before_insert_users`
BEFORE INSERT ON `users`
FOR EACH ROW
BEGIN
  SET NEW.email = LOWER(TRIM(NEW.email));
  SET NEW.full_name = TRIM(NEW.full_name);
END$$

-- Trigger: normalizar email e nome antes de atualizar usuário
CREATE TRIGGER `before_update_users`
BEFORE UPDATE ON `users`
FOR EACH ROW
BEGIN
  SET NEW.email = LOWER(TRIM(NEW.email));
  SET NEW.full_name = TRIM(NEW.full_name);
END$$

-- Trigger: garantir status e evitar datas passadas ao inserir appointment
CREATE TRIGGER `before_insert_appointments`
BEFORE INSERT ON `appointments`
FOR EACH ROW
BEGIN
  IF NEW.status IS NULL THEN
    SET NEW.status = 'Agendado';
  END IF;

  IF NEW.appointment_date < CURDATE() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Não é permitido agendar consultas em datas passadas.';
  END IF;
END$$

-- Trigger: garantir status e evitar datas passadas ao atualizar appointment
CREATE TRIGGER `before_update_appointments`
BEFORE UPDATE ON `appointments`
FOR EACH ROW
BEGIN
  IF NEW.status IS NULL THEN
    SET NEW.status = 'Agendado';
  END IF;

  IF NEW.appointment_date < CURDATE() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Não é permitido reagendar consultas para datas passadas.';
  END IF;
END$$

-- Procedure: criar agendamento com validação de usuário ativo
CREATE PROCEDURE `sp_create_appointment`(
    IN p_user_id INT,
    IN p_service VARCHAR(100),
    IN p_appointment_date DATE,
    IN p_appointment_time TIME,
    IN p_notes TEXT,
    IN p_patient_address VARCHAR(255),
    IN p_patient_phone VARCHAR(20)
)
BEGIN
    DECLARE v_user_count INT;

    SELECT COUNT(*)
      INTO v_user_count
      FROM users
     WHERE id = p_user_id
       AND status = 'active';

    IF v_user_count = 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Usuário inexistente ou inativo.';
    END IF;

    INSERT INTO appointments
        (user_id, service, appointment_date, appointment_time, notes, patient_address, patient_phone)
    VALUES
        (p_user_id, p_service, p_appointment_date, p_appointment_time, p_notes, p_patient_address, p_patient_phone);
END$$

-- Procedure: atualizar status de um agendamento
CREATE PROCEDURE `sp_update_appointment_status`(
    IN p_appointment_id INT,
    IN p_new_status VARCHAR(20)
)
BEGIN
    IF p_new_status NOT IN ('Agendado', 'Completo', 'Cancelado') THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Status inválido. Use Agendado, Completo ou Cancelado.';
    END IF;

    UPDATE appointments
       SET status = p_new_status
     WHERE id = p_appointment_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Agendamento não encontrado.';
    END IF;
END$$

-- Procedure: listar agendamentos de um usuário
CREATE PROCEDURE `sp_get_user_appointments`(
    IN p_user_id INT
)
BEGIN
    SELECT 
        a.id,
        a.service,
        a.appointment_date,
        a.appointment_time,
        a.status,
        a.notes,
        a.patient_address,
        a.patient_phone,
        s.price AS service_price
    FROM appointments a
    LEFT JOIN services s
           ON a.service = s.name
    WHERE a.user_id = p_user_id
    ORDER BY a.appointment_date, a.appointment_time;
END$$

DELIMITER ;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;