-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : mar. 05 mai 2026 à 01:13
-- Version du serveur : 10.4.32-MariaDB
-- Version de PHP : 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `school_management`
--

DELIMITER $$
--
-- Fonctions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `check_room_time_conflict` (`p_class_id` INT, `p_room` VARCHAR(50), `p_day` VARCHAR(20), `p_start_time` TIME, `p_duration` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE conflict INT DEFAULT 0;
    SELECT COUNT(*) INTO conflict
    FROM classes c
    JOIN class_schedules cs ON c.id = cs.class_id
    WHERE c.room = p_room
      AND cs.day = p_day
      AND c.id != p_class_id
      AND c.status NOT IN ('cancelled', 'completed')
      AND (
          cs.time < ADDTIME(p_start_time, SEC_TO_TIME(p_duration * 3600))
          AND ADDTIME(cs.time, SEC_TO_TIME(c.duration_hours * 3600)) > p_start_time
      );
    RETURN conflict > 0;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `assignments`
--

CREATE TABLE `assignments` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `due_date` date NOT NULL,
  `max_score` int(11) DEFAULT 100,
  `file_url` varchar(500) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `assignments`
--

INSERT INTO `assignments` (`id`, `class_id`, `title`, `description`, `due_date`, `max_score`, `file_url`, `created_by`, `file_name`, `created_at`) VALUES
(7, 9, 'zx', 'zx', '2026-05-09', 100, 'uploads/assignments/1777748293_69f64945c0bd6.png', 9, NULL, '2026-05-02 19:58:13'),
(10, 10, 'harbinaaaaaaaaaaaaaa', '', '2026-05-11', 20, 'uploads/assignments/1777935302_69f923c690217.pdf', 9, NULL, '2026-05-04 23:55:02'),
(11, 10, 'ananas', '', '2026-05-11', 100, 'uploads/assignments/1777935603_69f924f38dac0.pdf', 9, NULL, '2026-05-05 00:00:03');

--
-- Déclencheurs `assignments`
--
DELIMITER $$
CREATE TRIGGER `before_assignment_insert_logic` BEFORE INSERT ON `assignments` FOR EACH ROW BEGIN
    -- Ensure title is not empty
    IF NEW.`title` IS NULL OR TRIM(NEW.`title`) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Assignment title is required!';
    END IF;

    -- Optional: Ensure Due Date is not too far in the past (must be at least from today)
    -- This ensures teachers don't create assignments that are already expired
    IF NEW.`due_date` < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Assignment due date cannot be in the past!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `attendance`
--

CREATE TABLE `attendance` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late') DEFAULT 'present',
  `arrival_time` time DEFAULT NULL,
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `attendance`
--

INSERT INTO `attendance` (`id`, `class_id`, `student_id`, `date`, `status`, `arrival_time`, `notes`) VALUES
(45, 9, 4, '2026-05-03', 'present', '00:00:00', 'excellent'),
(46, 9, 3, '2026-05-03', 'present', '00:00:00', 'good'),
(47, 10, 33, '2026-05-04', 'present', '00:00:00', ''),
(48, 10, 4, '2026-05-04', 'present', '00:00:00', ''),
(49, 10, 3, '2026-05-04', 'present', '00:00:00', ''),
(50, 10, 33, '2026-04-27', 'absent', '00:00:00', ''),
(51, 10, 4, '2026-04-27', 'present', '00:00:00', ''),
(52, 10, 3, '2026-04-27', 'present', '00:00:00', '');

--
-- Déclencheurs `attendance`
--
DELIMITER $$
CREATE TRIGGER `before_attendance_insert` BEFORE INSERT ON `attendance` FOR EACH ROW BEGIN
    IF NEW.`date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Attendance date cannot be in the future!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `attendances`
--

CREATE TABLE `attendances` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late') DEFAULT 'present'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déclencheurs `attendances`
--
DELIMITER $$
CREATE TRIGGER `before_attendances_insert_alt` BEFORE INSERT ON `attendances` FOR EACH ROW BEGIN
    IF NEW.`date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Attendance date cannot be in the future!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `classes`
--

CREATE TABLE `classes` (
  `id` int(11) NOT NULL,
  `class_name` varchar(100) NOT NULL,
  `language` varchar(50) NOT NULL,
  `level` varchar(50) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `schedule_day` varchar(20) NOT NULL,
  `schedule_time` time NOT NULL,
  `duration_hours` int(11) NOT NULL,
  `room` varchar(50) DEFAULT NULL,
  `current_students` int(11) DEFAULT 0,
  `min_students` int(11) DEFAULT 5,
  `max_students` int(11) DEFAULT 20,
  `price` decimal(10,2) NOT NULL,
  `start_date` date DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` enum('waiting','active','completed','cancelled') DEFAULT 'waiting',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `classes`
--

INSERT INTO `classes` (`id`, `class_name`, `language`, `level`, `teacher_id`, `schedule_day`, `schedule_time`, `duration_hours`, `room`, `current_students`, `min_students`, `max_students`, `price`, `start_date`, `description`, `status`, `created_at`) VALUES
(9, 'Test Class', 'Arabic', 'Advanced', 9, 'Friday', '10:00:00', 5, '100', 2, 1, 10, 2500.00, NULL, 'wiiiw', 'active', '2026-05-02 13:28:20'),
(10, 'cnn', 'Arabic', 'Beginner', 9, 'Friday', '08:00:00', 2, '25', 3, 1, 4, 58.00, NULL, 'z', 'active', '2026-05-03 08:17:41');

--
-- Déclencheurs `classes`
--
DELIMITER $$
CREATE TRIGGER `before_class_insert_logic` BEFORE INSERT ON `classes` FOR EACH ROW BEGIN
    -- Ensure Start Date is not in the past
    IF NEW.`start_date` < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class start date cannot be in the past!';
    END IF;

    -- Ensure Class Name is provided
    IF NEW.`class_name` IS NULL OR TRIM(NEW.`class_name`) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class name is required!';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_class_insert_validation` BEFORE INSERT ON `classes` FOR EACH ROW BEGIN
    -- Duration validation
    IF NEW.duration_hours < 1 OR NEW.duration_hours > 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Duration hours must be between 1 and 8 hours';
    END IF;
    
    IF NEW.duration_hours != FLOOR(NEW.duration_hours) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Duration hours must be a whole number (no decimals)';
    END IF;
    
    -- Min/Max students validation
    IF NEW.min_students > NEW.max_students THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Minimum students cannot be greater than maximum students';
    END IF;
    
    IF NEW.min_students < 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Minimum students must be at least 1';
    END IF;
    
    IF NEW.max_students > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Maximum students cannot exceed 100';
    END IF;
    
    -- ============================================
    -- TIME VALIDATION (New)
    -- ============================================
    -- Extract hour from schedule_time
    SET @hour = HOUR(NEW.schedule_time);
    
    -- Time must be between 08:00 and 16:00 (start time)
    IF @hour < 8 OR @hour > 16 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class start time must be between 08:00 and 16:00';
    END IF;
    
    -- Minutes must be zero (no minutes allowed)
    IF MINUTE(NEW.schedule_time) != 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class start time must be a full hour (no minutes)';
    END IF;
    
    -- End time validation (start time + duration)
    SET @end_hour = @hour + NEW.duration_hours;
    IF @end_hour > 17 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class would end after 17:00, which is not allowed';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_class_update_validation` BEFORE UPDATE ON `classes` FOR EACH ROW BEGIN
    IF NEW.duration_hours < 1 OR NEW.duration_hours > 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Duration hours must be between 1 and 8 hours';
    END IF;
    
    IF NEW.duration_hours != FLOOR(NEW.duration_hours) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Duration hours must be a whole number (no decimals)';
    END IF;
    
    IF NEW.min_students > NEW.max_students THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Minimum students cannot be greater than maximum students';
    END IF;
    
    IF NEW.min_students < 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Minimum students must be at least 1';
    END IF;
    
    IF NEW.max_students > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Maximum students cannot exceed 100';
    END IF;
    
    IF NEW.max_students < OLD.current_students THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot reduce max_students below current enrollment';
    END IF;
    
    -- Time validation
    SET @hour = HOUR(NEW.schedule_time);
    
    IF @hour < 8 OR @hour > 16 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class start time must be between 08:00 and 16:00';
    END IF;
    
    IF MINUTE(NEW.schedule_time) != 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class start time must be a full hour (no minutes)';
    END IF;
    
    SET @end_hour = @hour + NEW.duration_hours;
    IF @end_hour > 17 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Class would end after 17:00, which is not allowed';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `class_schedules`
--

CREATE TABLE `class_schedules` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `day` varchar(20) NOT NULL,
  `time` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `class_schedules`
--

INSERT INTO `class_schedules` (`id`, `class_id`, `day`, `time`) VALUES
(64, 9, 'Friday', '10:00:00'),
(66, 9, 'Sunday', '11:00:00'),
(65, 9, 'Tuesday', '11:00:00'),
(79, 10, 'Friday', '08:00:00'),
(80, 10, 'Monday', '08:00:00');

--
-- Déclencheurs `class_schedules`
--
DELIMITER $$
CREATE TRIGGER `before_class_schedule_insert_conflict` BEFORE INSERT ON `class_schedules` FOR EACH ROW BEGIN
    DECLARE class_room VARCHAR(50);
    DECLARE class_duration INT;
    SELECT room, duration_hours INTO class_room, class_duration
    FROM classes WHERE id = NEW.class_id;
    IF class_room IS NOT NULL AND class_room != '' THEN
        IF check_room_time_conflict(NEW.class_id, class_room, NEW.day, NEW.time, class_duration) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflict: Another class already uses this room at the same time period.';
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_class_schedule_update_conflict` BEFORE UPDATE ON `class_schedules` FOR EACH ROW BEGIN
    DECLARE class_room VARCHAR(50);
    DECLARE class_duration INT;
    IF (NEW.day != OLD.day OR NEW.time != OLD.time) THEN
        SELECT room, duration_hours INTO class_room, class_duration
        FROM classes WHERE id = NEW.class_id;
        IF class_room IS NOT NULL AND class_room != '' THEN
            IF check_room_time_conflict(NEW.class_id, class_room, NEW.day, NEW.time, class_duration) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflict: Another class already uses this room at the same time period.';
            END IF;
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `conversations`
--

CREATE TABLE `conversations` (
  `id` int(11) NOT NULL,
  `participant1_id` int(11) NOT NULL,
  `participant2_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `conversations`
--

INSERT INTO `conversations` (`id`, `participant1_id`, `participant2_id`, `created_at`, `updated_at`) VALUES
(1, 2, 10, '2026-04-25 15:47:03', '2026-04-25 15:47:03'),
(2, 2, 14, '2026-04-25 15:47:32', '2026-04-25 15:47:32'),
(3, 2, 25, '2026-04-26 07:03:49', '2026-04-26 07:03:49'),
(4, 27, 9, '2026-05-01 16:50:47', '2026-05-01 16:50:47'),
(5, 27, 27, '2026-05-01 16:50:56', '2026-05-01 16:50:56'),
(6, 2, 27, '2026-05-01 16:56:26', '2026-05-01 16:56:26'),
(7, 27, 19, '2026-05-01 18:01:04', '2026-05-01 18:01:04'),
(8, 4, 9, '2026-05-01 20:01:22', '2026-05-01 20:01:22'),
(9, 2, 9, '2026-05-02 21:13:28', '2026-05-02 21:13:28'),
(10, 9, 14, '2026-05-02 21:58:00', '2026-05-02 21:58:00'),
(11, 28, 9, '2026-05-04 03:27:13', '2026-05-04 03:27:13'),
(12, 2, 28, '2026-05-04 03:31:25', '2026-05-04 03:31:25'),
(13, 3, 9, '2026-05-04 14:02:45', '2026-05-04 14:02:45'),
(14, 2, 3, '2026-05-04 17:17:48', '2026-05-04 17:17:48');

-- --------------------------------------------------------

--
-- Structure de la table `enrollments`
--

CREATE TABLE `enrollments` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `enrollment_date` date NOT NULL,
  `status` enum('pending','active','completed','cancelled') DEFAULT 'pending',
  `amount_paid` decimal(10,2) DEFAULT 0.00,
  `payment_status` enum('pending','partial','paid') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `enrollments`
--

INSERT INTO `enrollments` (`id`, `student_id`, `class_id`, `enrollment_date`, `status`, `amount_paid`, `payment_status`, `notes`, `created_at`) VALUES
(22, 3, 9, '2026-05-02', 'active', 1000.00, 'partial', '', '2026-05-02 13:28:58'),
(23, 4, 9, '2026-05-02', 'active', 1200.00, 'partial', '', '2026-05-02 13:28:58'),
(24, 33, 10, '2026-05-03', 'active', 0.00, 'pending', '', '2026-05-03 08:18:06'),
(25, 4, 10, '2026-05-03', 'active', 0.00, 'pending', '', '2026-05-03 08:20:01'),
(26, 3, 10, '2026-05-04', 'active', 48.00, 'partial', '', '2026-05-04 18:14:36');

--
-- Déclencheurs `enrollments`
--
DELIMITER $$
CREATE TRIGGER `after_delete_enrollment` AFTER DELETE ON `enrollments` FOR EACH ROW BEGIN
    UPDATE classes 
    SET current_students = (
        SELECT COUNT(*) 
        FROM enrollments 
        WHERE class_id = OLD.class_id 
        AND status = 'active'
    )
    WHERE id = OLD.class_id;
    
    UPDATE classes 
    SET status = 'waiting' 
    WHERE id = OLD.class_id 
    AND status = 'active' 
    AND current_students < min_students;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_insert_enrollment` AFTER INSERT ON `enrollments` FOR EACH ROW BEGIN
    UPDATE classes 
    SET current_students = (
        SELECT COUNT(*) 
        FROM enrollments 
        WHERE class_id = NEW.class_id 
        AND status = 'active'
    )
    WHERE id = NEW.class_id;
    
    UPDATE classes 
    SET status = 'active' 
    WHERE id = NEW.class_id 
    AND status = 'waiting' 
    AND current_students >= min_students;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_update_enrollment` AFTER UPDATE ON `enrollments` FOR EACH ROW BEGIN
    UPDATE classes 
    SET current_students = (
        SELECT COUNT(*) 
        FROM enrollments 
        WHERE class_id = NEW.class_id 
        AND status = 'active'
    )
    WHERE id = NEW.class_id;
    
    UPDATE classes 
    SET status = CASE
        WHEN current_students >= min_students THEN 'active'
        WHEN current_students < min_students THEN 'waiting'
        ELSE status
    END
    WHERE id = NEW.class_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_enrollment_insert_logic` BEFORE INSERT ON `enrollments` FOR EACH ROW BEGIN
    DECLARE current_count INT;
    DECLARE max_cap INT;

    -- 1. Check Capacity
    SELECT COUNT(*) INTO current_count FROM `enrollments` WHERE `class_id` = NEW.`class_id` AND `status` = 'active';
    SELECT `max_students` INTO max_cap FROM `classes` WHERE `id` = NEW.`class_id`;

    IF current_count >= max_cap THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: This class has reached its maximum capacity!';
    END IF;

    -- 2. Validate Amount Paid
    IF NEW.`amount_paid` < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Amount paid cannot be negative!';
    END IF;

    -- 3. Block future enrollment dates
    IF NEW.`enrollment_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Enrollment date cannot be in the future!';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_enrollment` BEFORE INSERT ON `enrollments` FOR EACH ROW BEGIN
    DECLARE v_current_students INT;
    DECLARE v_max_students INT;
    DECLARE v_min_students INT;
    
    -- جلب معلومات الفصل
    SELECT current_students, max_students, min_students 
    INTO v_current_students, v_max_students, v_min_students
    FROM classes 
    WHERE id = NEW.class_id;
    
    -- التحقق من أن min_students <= max_students
    IF v_min_students > v_max_students THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'خطأ: الحد الأدنى أكبر من الحد الأقصى';
    END IF;
    
    -- التحقق من أن الفصل لم يمتلئ
    IF v_current_students >= v_max_students THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'الفصل ممتلئ';
    END IF;
    
    -- التحقق من عدم وجود تسجيل مكرر
    IF EXISTS (
        SELECT 1 FROM enrollments 
        WHERE student_id = NEW.student_id 
        AND class_id = NEW.class_id 
        AND status IN ('active', 'pending')
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'الطالب مسجل مسبقا';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `expenses`
--

CREATE TABLE `expenses` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `vendor` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déclencheurs `expenses`
--
DELIMITER $$
CREATE TRIGGER `before_expense_insert_logic` BEFORE INSERT ON `expenses` FOR EACH ROW BEGIN
    -- Block future expense dates
    IF NEW.`date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Expense date cannot be in the future!';
    END IF;

    -- Ensure category is provided
    IF NEW.`category` IS NULL OR TRIM(NEW.`category`) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Expense category is required!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `grades`
--

CREATE TABLE `grades` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `assignment_name` varchar(255) NOT NULL,
  `score` decimal(5,2) NOT NULL,
  `max_score` decimal(5,2) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `grades`
--

INSERT INTO `grades` (`id`, `class_id`, `student_id`, `assignment_name`, `score`, `max_score`, `date`) VALUES
(9, 9, 4, 'analyse', 14.00, 20.00, '2026-05-04'),
(10, 9, 3, 'analyse', 16.50, 20.00, '2026-05-04'),
(11, 10, 33, 'i3rab', 18.00, 20.00, '2026-05-04'),
(12, 10, 4, 'i3rab', 15.00, 20.00, '2026-05-04'),
(13, 10, 3, 'i3rab', 16.00, 20.00, '2026-05-04');

--
-- Déclencheurs `grades`
--
DELIMITER $$
CREATE TRIGGER `before_grade_insert_logic` BEFORE INSERT ON `grades` FOR EACH ROW BEGIN
    -- Prevent future grading dates
    IF NEW.`date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Grade date cannot be in the future!';
    END IF;

    -- Ensure max_score is greater than zero
    IF NEW.`max_score` <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Maximum score must be greater than zero!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `manager_settings`
--

CREATE TABLE `manager_settings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `theme` enum('light','dark') DEFAULT 'light',
  `email_notifications` tinyint(1) DEFAULT 1,
  `push_notifications` tinyint(1) DEFAULT 1,
  `new_account_alerts` tinyint(1) DEFAULT 1,
  `login_alerts` tinyint(1) DEFAULT 1,
  `two_factor_auth` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `manager_settings`
--

INSERT INTO `manager_settings` (`id`, `user_id`, `theme`, `email_notifications`, `push_notifications`, `new_account_alerts`, `login_alerts`, `two_factor_auth`) VALUES
(1, 2, 'light', 1, 1, 1, 1, 0),
(26, 27, 'light', 1, 1, 1, 1, 0);

-- --------------------------------------------------------

--
-- Structure de la table `meetings`
--

CREATE TABLE `meetings` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `with_type` enum('teacher','parent','staff','student') NOT NULL,
  `with_id` int(11) NOT NULL,
  `with_name` varchar(255) NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `agenda` text DEFAULT NULL,
  `status` enum('pending','accepted','rejected','scheduled','completed','cancelled') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `meetings`
--

INSERT INTO `meetings` (`id`, `teacher_id`, `parent_id`, `title`, `with_type`, `with_id`, `with_name`, `date`, `time`, `location`, `agenda`, `status`, `created_at`, `updated_at`) VALUES
(28, 9, NULL, 'Meeting Request', '', 2, 'booo3la', '2026-05-14', '11:00:00', '12', '', 'accepted', '2026-05-03 18:59:23', '2026-05-03 20:25:34'),
(29, 10, NULL, 'Meeting Request', '', 2, 'booo3la', '2026-05-09', '21:31:00', '12', '', 'rejected', '2026-05-03 20:31:45', '2026-05-03 20:32:55'),
(30, 9, NULL, 'Meeting Request', '', 2, 'booo3la', '2026-05-13', '23:19:00', '13', '', 'accepted', '2026-05-03 21:19:47', '2026-05-03 21:20:41'),
(31, 27, NULL, 'xccx', 'teacher', 9, 'Adil Retima', '2026-05-04', '12:00:00', 'xxx', 'xx', 'cancelled', '2026-05-03 21:56:33', '2026-05-03 21:57:34'),
(32, 2, NULL, 'tawil', 'teacher', 9, 'Adil Retima', '2026-05-05', '03:16:00', '12', '', 'accepted', '2026-05-04 01:15:35', '2026-05-04 01:48:41'),
(33, 2, NULL, 'talk', 'teacher', 9, 'Adil Retima', '2026-05-04', '07:51:00', 'school', '', 'accepted', '2026-05-04 01:51:15', '2026-05-04 01:52:02'),
(34, 28, NULL, 'discuss', 'teacher', 9, 'Adil Retima', '2026-05-04', '10:32:00', 'school', '', 'cancelled', '2026-05-04 03:32:24', '2026-05-04 03:32:40'),
(35, 28, NULL, 'disscuss', 'teacher', 9, 'Adil Retima', '2026-05-04', '10:33:00', 'school', '', 'accepted', '2026-05-04 03:33:34', '2026-05-04 03:34:13'),
(36, 2, NULL, 'asque T5rj', 'teacher', 9, 'Adil Retima', '2026-05-04', '10:38:00', '', '', 'rejected', '2026-05-04 03:38:08', '2026-05-04 03:43:34'),
(37, 2, NULL, 'tytyt', 'staff', 28, 'bassstop', '2026-05-04', '10:44:00', 'sss', '', 'accepted', '2026-05-04 03:44:28', '2026-05-04 04:05:12'),
(38, 2, NULL, 'zzzzzz', 'staff', 28, 'bassstop', '2026-05-04', '09:48:00', 'scj', '', 'accepted', '2026-05-04 03:48:20', '2026-05-04 04:05:26'),
(39, 9, NULL, 'Meeting Request', '', 28, 'bassstop', '2026-05-04', '09:51:00', 'sss', '', 'rejected', '2026-05-04 03:51:30', '2026-05-04 04:06:45'),
(40, 28, NULL, 'pending', 'teacher', 9, 'Adil Retima', '2026-05-04', '05:07:00', 'room', '', 'accepted', '2026-05-04 04:06:10', '2026-05-04 04:06:38'),
(41, 28, NULL, 'pending', 'parent', 14, 'mounir messaoudene', '2026-05-04', '11:07:00', 'ed', '', 'cancelled', '2026-05-04 04:07:57', '2026-05-04 04:09:37');

--
-- Déclencheurs `meetings`
--
DELIMITER $$
CREATE TRIGGER `before_meeting_insert_logic` BEFORE INSERT ON `meetings` FOR EACH ROW BEGIN
    -- Ensure meeting date is not too old (at least from today onwards)
    IF NEW.`date` < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Meeting date cannot be in the past!';
    END IF;

    -- Ensure title is provided
    IF NEW.`title` IS NULL OR TRIM(NEW.`title`) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Meeting title is required!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `conversation_id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `messages`
--

INSERT INTO `messages` (`id`, `conversation_id`, `sender_id`, `receiver_id`, `message`, `is_read`, `created_at`) VALUES
(1, 1, 2, 10, 'ئ', 0, '2026-04-25 15:47:03'),
(2, 1, 2, 10, 'ش', 0, '2026-04-25 15:47:13'),
(3, 2, 2, 14, 'ش', 1, '2026-04-25 15:47:32'),
(4, 2, 2, 14, 'ش', 1, '2026-04-25 15:53:42'),
(5, 2, 2, 14, 'ء', 1, '2026-04-25 15:53:47'),
(10, 6, 2, 27, 'aaa', 1, '2026-05-01 16:56:26'),
(11, 2, 2, 14, 'x', 1, '2026-05-01 16:56:38'),
(12, 6, 27, 2, 'شش', 1, '2026-05-01 17:07:47'),
(13, 6, 27, 2, 'ش', 1, '2026-05-01 17:08:33'),
(14, 6, 27, 2, 'ش', 1, '2026-05-01 17:08:43'),
(15, 6, 27, 2, 'ء', 1, '2026-05-01 17:08:47'),
(16, 6, 2, 27, 'x', 1, '2026-05-01 17:10:23'),
(18, 8, 4, 9, 'xzzx', 1, '2026-05-01 20:01:22'),
(19, 9, 2, 9, 'ئءء', 1, '2026-05-02 21:13:28'),
(20, 10, 9, 14, 'aa', 1, '2026-05-02 21:58:00'),
(21, 6, 2, 27, 'x', 1, '2026-05-03 21:39:06'),
(22, 9, 2, 9, 'hello', 1, '2026-05-04 00:11:31'),
(23, 9, 9, 2, 'hello', 1, '2026-05-04 00:56:29'),
(24, 9, 2, 9, 'jdkd', 1, '2026-05-04 01:07:44'),
(25, 11, 28, 9, 'tawil hhh', 1, '2026-05-04 03:27:13'),
(26, 11, 9, 28, 'hhhh tawlan', 1, '2026-05-04 03:28:15'),
(27, 11, 9, 28, 'abababa', 1, '2026-05-04 03:29:47'),
(28, 11, 9, 28, 'a5dm', 1, '2026-05-04 03:30:35'),
(29, 12, 2, 28, 'a5kkk', 1, '2026-05-04 03:31:25'),
(30, 13, 3, 9, 'hhh', 1, '2026-05-04 14:02:45'),
(31, 13, 9, 3, 'bien', 1, '2026-05-04 14:04:00'),
(32, 13, 3, 9, 'hola', 1, '2026-05-04 16:39:21'),
(33, 14, 2, 3, 'heelo', 1, '2026-05-04 17:17:48');

--
-- Déclencheurs `messages`
--
DELIMITER $$
CREATE TRIGGER `before_message_insert_logic` BEFORE INSERT ON `messages` FOR EACH ROW BEGIN
    -- Prevent sending empty messages
    IF NEW.`message` IS NULL OR TRIM(NEW.`message`) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot send an empty message!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `parents`
--

CREATE TABLE `parents` (
  `user_id` int(11) NOT NULL,
  `parent_id` varchar(50) NOT NULL,
  `gender` enum('Male','Female') DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `alt_phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `registration_date` date DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `parents`
--

INSERT INTO `parents` (`user_id`, `parent_id`, `gender`, `phone`, `alt_phone`, `address`, `notes`, `registration_date`, `status`) VALUES
(14, 'mounir', 'Male', '0654356741', '', 'kdjfldsdlekfld', 'iwww', '2026-04-07', 'active'),
(31, 'koko', 'Male', '0987654321', '', 'sasa', '', '0000-00-00', 'active');

--
-- Déclencheurs `parents`
--
DELIMITER $$
CREATE TRIGGER `before_parent_insert_logic` BEFORE INSERT ON `parents` FOR EACH ROW BEGIN
    IF NEW.`registration_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Registration date cannot be in the future!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `type` enum('student','salary') NOT NULL COMMENT 'نوع الدفع',
  `reference_id` int(11) NOT NULL COMMENT 'student_id أو employee_id',
  `amount` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `due_date` date DEFAULT NULL,
  `status` enum('paid','pending','overdue') DEFAULT 'paid'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `payments`
--

INSERT INTO `payments` (`id`, `student_id`, `type`, `reference_id`, `amount`, `date`, `notes`, `created_at`, `due_date`, `status`) VALUES
(4, 0, 'salary', 9, 20.00, '2026-04-26', '', '2026-04-26 00:38:35', NULL, 'paid'),
(6, 0, 'salary', 21, 11.00, '2026-04-26', '', '2026-04-26 00:45:29', NULL, 'paid'),
(17, 4, 'student', 4, 1200.00, '2026-05-02', '', '2026-05-02 13:33:09', NULL, 'paid'),
(18, 3, 'student', 3, 1000.00, '2026-05-04', '1 tranche', '2026-05-04 17:41:00', NULL, 'paid'),
(19, 1, 'student', 1, 2500.00, '2026-05-01', 'Tuition - June', '2026-05-04 18:07:52', '2026-06-15', 'pending'),
(21, 3, 'student', 3, 48.00, '2026-05-04', '', '2026-05-04 20:13:43', NULL, 'paid');

--
-- Déclencheurs `payments`
--
DELIMITER $$
CREATE TRIGGER `before_payment_insert_logic` BEFORE INSERT ON `payments` FOR EACH ROW BEGIN
    -- Block negative payments (Double check)
    IF NEW.`amount` < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Payment amount cannot be negative!';
    END IF;

    -- Optional: Ensure Due Date is not before Payment Date
    IF NEW.`due_date` IS NOT NULL AND NEW.`due_date` < NEW.`date` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Due date cannot be earlier than payment date!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `resources`
--

CREATE TABLE `resources` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `file_url` varchar(500) NOT NULL,
  `file_data` longblob DEFAULT NULL,
  `file_size` int(11) DEFAULT NULL,
  `file_name` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `resources`
--

INSERT INTO `resources` (`id`, `teacher_id`, `class_id`, `type`, `title`, `description`, `file_url`, `file_data`, `file_size`, `file_name`, `created_at`) VALUES
(11, 9, 5, 'document', 'لالا', 'لالالا', '', 0x89504e470d0a1a0a0000000d49484452000005440000006e0806000000ef7319a0000000017352474200aece1ce90000000467414d410000b18f0bfc6105000000097048597300000ec300000ec301c76fa8640000293549444154785eeddd6f905c5779e7f15ff7ccc8a399d14842e3916d348008d84e24b9f863426c64076c67f13ae031a90a9822868275c82b5c5b6c42b9ca4ed5562dd42621cb0bb2af12f2a74c5c3695b816855d0a5225e36061968404f08c2843609544825863094bb2461acdf4f4dd17d3b77de6d139f79edb7dfbcf4c7f3f5553d63de7b9cf39f7dc3b3ddd8f6f7757f65e776d22000000000000001800955bdff75e0aa2000000000000000642853b44010000000000000c8aaa6d0000000000000080cd8a82280000000000008081414114000000000000c0c0a0200a000000000000a02f254952e827060551000000000000007dc35be04c242589544f94d4eb4aea75a99eacb5b961be7d8dcadeebae4d768e8c68fbc888c686863454a9d81800000000000000e898b48099ac6da8def8efc8d898c6a7a6347ed5551addb64d4343c3cd3b3ceb9256576b5a7ae9252d3effbc164f9dd2ca850b52a5b21653a928ad74561a35cfd52451e58e37bd31191b1a6a74010000000000004077a405d0f47ece7a9228a927dafeca6bf48ad75fab2d6363d29e6b34343323eddc218d8f4b5b46d6829757a4c545e9c5335a3d7e5c3af1532d5fb8a09ffdf30f75f6273f55a55a51b55108ade8e50269e5eeb7dc18be7f14000000000000003ac02d862649a27a9268e2ca695d75c3015577edd2f09bde20cdecb1bb653b7e42b57ffaaeeaa74febf967e774fe8505552b1555d2bb452b150aa200000000d0efc6c627b465f48ae6dbfd0000f0499244cb4b977461f1bcedea3b6e31b45e4f544feabae60d6fd4e4cc8c860ede54bc106a1d3fa1da916feaa5e3c7f5d3ef7e47d54a55d52a77880200000040df1b1b9fd0155b476d33000041972e2e955a149d1e1fd6f4f888f64f8fe9caf1617d7fe1a20e1f3b67c3a2ad2f86d655ddb245afbae9666db9f6751afae55ba4b2fe07609268f5ef9ed6f20f7fa47ffbe633aa2f2fab5aadb65710dd3f3aa203576cd1bed111ed1e1ed2dcd2b25ea8d535776959f34b2b361c0000000050d08e5dbbb8331400504892243a73fab46d2e6cfff4567df2b6f09d9a0b8b2b7af2d84b7a7c3e7e2c5b0cad8c8c68efadb76acb8d6f56e586fd36bc14c9b3f35afef63fead8d7bfae6465a5b582e8f470550fec9ad481d1c607987a2cd4ea7ae8e48b5aa8d56d170000000020d2cea929dbd434f5994febd4c77fc736a345539ff9b424f5644dd3b15dbd980750367b6dfbae6b3726af3fe58beb855e3e6ee479f1d429db146d7a7c581f7beb553a30bdb5d9f6f8fccf34bf704192b47b7c44bf30bd55b7ef9d94241d3e764e5f983fad85c55a33dec71643ebf544af7dc73b34fa4bbfd8b162682a79765e4bfff7eff5ffbef6b5e205d1fda323fad4ee1db6d96ba156d793e797f4d8d945dbd555871e7da4f9efd90f7c705d9f4c7fca17d78e748cb2f3765237d625d6465c3fb48ef38d7e54f6755976be2c797f07637473bee83dfb1c6010cefba1471f1988e3ec07a1c713ce4158a820dacf2fc237aa7e59d37e99c7a0e33cb42f760df30aa2aed89cddd26ff371b55310fde377bf46d3e3239a5bb8a8dde3c392a48f7ee95f6cd8bac2e9c2e28a1e7ef244665134498ba149a27abdae6bdef0064dfee25b34f4f65b6d68cbce9d3aadc9a95db65992b4fad4d775eeefff4155db91657ab81a5d0c5523feb689514d0f171aa6eb663ff0c1e64fbf3af4e82397bd38e9b48db02ed8987a713d03c83668bf97651f6fd9f97ac92d560dcaf3806e9fbbcd74bd948d7529cebe009ffacca79b3fbe7600e847a73efe3bcd1f14177aec6fd57fbb6d8fa6c74774f8d839fdee93276c77d374a350fa47df7a5e8fcfff4cd3e3237adf7e7f2152e9dda16951b45ed7f895d3da36f3aab5cf0c2dd1335ffc1bdbd434f4cbb76872e655c50aa20fec5abb0d3675f8fcd2baedd4e367d66e9f95f3f6fa18e99343fbd3ae417a420f0080c5df41f45adef33afbdc2f14978a8d8b91e6f0fd7e84c6f1b5f58a5db77e9a5b51e939d8a8f30700a017a64afee894fdd35b75607aabe6162eea8fbe75d27637a57786a69f2ffae4b1b39a5bb8a8dbf74e36df467f99c6dda1499268354974f50d3768f8e04de57d8192a4e3cffd40478f1cd1d123dfb05d6b2a150d1dbc29fe2df3b74f5cb1aeb079f8fc923e7bfa25bd7ffbb8eedd31d66cffece9733a7cfed265ed0f9d3c93fb454b594f48bba5537368376fbbfbb76bd0c747b9f2ce675e3fd00b655f9765e76b57de7cf2fa379ab28fa7ec7cbd54f6b1d8e296cdeb1bcfd766fb52be985859e3c88c153bbf18edeeef2a3357b7e4cd39af7f10f9de321f7a8b66e86da731f1f2f4a76c9ccb378ecbd77feae3bf73596c68ec18b1b9f2e28acecfc6a8cdb854e87cc5b2e3d9e3b1796dbcda3c6f364605e252a1b1b28e23962fafcbf65b31f1a1187b0c695b6a2a50dc0ab567891d532dc6ba6c4ccacdeb532457aa68ce505c9ed835293bcee5c6f962a69cebc2b72eadbc653e7dabfcc34f9ed0fcc2c5669b9cb7ccdbcf174ddf2abf16bb570b8b2b97bdbd3efdecd07a9268b55ed7b6abafd635b7deaae1d977ad8bb38e1ef9868e3ff7431d7fee396d9fdaa53dd75fa799ebafd7f6a9a9cbde167ff4c837f495cffd5973fbcefb3fa27d07dfb62e26155d10b5054e35ee047decec62b32f2d86dae2a91b9ba5c8931ffb64589efd6262acbc39d89cb171a9507c48284fcae6f3c5db9856145d170562db895320368f3b779bd7e6cbeb4fb51a27131b5a575f7b2f8f4326362b2e8b1dcf4af316395679f2fa628a88cd1713177b2c87029f9be66bcfca938a1d3756917c79fda9bcb82263ca934f9e354edb6c6c6c3e79626d9ced4fd9b85428dec7773db86cbf6f4cbbbf2fc695c6175dbf5836974ace6773d97e2b263e6f8d5dbef573e5b5a76c7f51369f327286e6d4aaf4ba0ce54dfb6d9b3cb1695f56be22f272b8ebe63bef76bfbc75f6f5bb6cbe18a1b9f8f8c6f7cdcfe6b2edeeb6cd69f755605c0562e5190fe18268e8c5b19c17dc592f946d9bdd0ec565b5d9ed941dc36d73dbedd8317cfbdab9a46dca892b32bfb2db5c79fd79dcfd43ff7663ed762a6df7b5b9edb6cd6ea77ced596da1b9dbb822ecbe76db95d5972a7abca1f6acf9f8da62f8c60ce5f2c5baed59fbdb36379765c775d93c215971b6cf6e17e15b135f3e5f9cdb6ef7f5b585e6e7db27c497ab9582e817ef7dbd0e1f3bb7eeee50b7206a8ba1a9b4289af67df44bc7d67d9668f3b343eb75d5ea75bdee1defd0d6fff84e69c6ff0df6e74e9dd6573ef7a73afedc0f9a6d9353533ad738a6c9a929bdefc14f68726a57e3aed06774f4c81127c39a7d070feae67beebeac781afd96f92b3d9f037aef8e31bd7ffbb81e3bbba8874e9e09164325695fc637d217953e114e7fdc76972fa61dee9333fb84d065e3da19dfeeefe6b47943e3fae658a6d87163cf5b285fbb7ce3bb63db716d7fcac6cd7a5e0c84e2dcf656153d8ed8f9b96d9de28ee56edbf654deb1badb593145d87c65ad5f9163096dbb6d59795c31e31691972f767e366e36b0ce326386f8f2b9edaebc6370b76d9c65e3dc36978d0be52b5bcc78b6dfddc7b75fccfac5f2e54adb5be15b679bcb8e9575bc31f3b37d59f962c51c4711be7c6e7bfaeff4c7b6b5236fffa2fd76bb1deebae489390731eb6caf0b3736661eed88995f51873cbf23365f68dc2ca15c785956b12196ef85b37d815e947db16eb75d597d65b0f97dc7ebdb4e85da5379f9d2fed8b85e0acdcd27ab2f6563ec762ff9ce47bbe7c21e9fddb6f2fa3ba1c8f166cdcfb77eeeb6db9ffeb83176bfb2f9e667e7d68ad87cb1c7179baf17d2b7babf90f1a54807a6c774607aab0e1f3ba785c5152d2cae343f3f747a7c44471b77954e8fbf5c076cde8999244a9244236363da32369e590cfd93dffe848e3ff703ed3b7850ef7df013fa2f7ff1a7facd3ffc7dbdf7c14f68dfc1833a77ea94bef07b7fa073a74e6be6faeb74e7fd1fd69df77f4493ceff447cef839fd09df77ff8b262a88a14440f8c6eb14d52a3283a3d5cd5fcd24ae6e785ee1e1eb24d2db34fa4ec7627f89e34fb9eacf9e2ba2134ae6f8e652a326e28c615ca5786ac9cbe717dc7106273fbf2b9db3139436c4e57deb8295f5c19732b9b9db7d5ade3b0f368655c9ba315bd1ad79595af95f9b942b9f3f2f9c675b7edd836ce0ae5b37c71be317d71edf0e5eea6b28e439e5c76bb0cede4b4fbdaed6e6a75ecd0f567afd5594fb1ca6e17151a3bcf21cf1da369bb5ac8d70da1b9d975ee954ecdcfe6b342e3a21cb12fbc0749bf141480226ca130f4bb1d6aef343b3f7457bafedd3a0757368a982f2c863ff2f2f0b1737af8c913ebee207d7cfeb43efaa5639a5fb8a8f985b5ef15da3fbdfe5de689a47ae3dbe527764d497bae59d7effa93dffe84d478cbfb9df77f5833d75fd7ec4b8b9f37dd73f7baa2a824ed3bf836ed3b78b324e9a67bee5eb79f155d103d595bb54d52e33343176a75ed1f1dd142adbeee0b955c734bcbb629e8d026f85078f4bfb25ee8f55abbc7112b1da71b63f5834e9f5fbb96a1750db5b7ca8edbae76f3757a9d07016b78b9cdb2269be1388a3e3e1c0a144353597d838ee7cff039e5f99c3a6bcaf966e2bcd83c3657bbf962b985826e8fbd19d873d6eedad95cede6eb8432e76773b59b2f95e6292bdf20e9c4f91834271b05d1f45be45db7ef9d6c7eb6a82b7d7bfc6ee7ced0a6a4718f68e36df313d75cada199191b2535be14498d8266e8f33f25e9e67b669b45d1e3cf3db7ae7de6faeb74f33db3ebe2ade882e851cf1722b99f19faa9dd3b9a6f9ff715455fa8d56d53905b78f13df1b54ff8baf9a4af57e36e0676edfa71fd62e6e75e9379b1fd2ee6783782328fa3c8f92d73dc544c9e4e8c5ba698f91559e77e1773bc9d7028a770b411d8b56b77fdcabeaeecdcdac95544d9c7d10badccf750c635dd4abeb2cd46bc6dbe97f29e3f63f328fbc5bd7bf751de9d48b6c0600b91695b5e9e4ef08d59f65a6d46659fb756f2655d579d62e717334f9f568eb7159dc8b999d9f3d1a9f3b219b97777ee9fdeaa3f7ef75eddbbffe5b79b7fecadbbf5befdaf087f8b7cce5da6492225f5bab66e9b9476eeb0dd92d42c6ece5c7fbdedba4c1a73fcb91fae6bbff3feffb46edb27ba203a7769fd1d9e8f9fb970d96786ba9f297af8fcd2baf885d5f0e70f14913e11edd5933e3b6eb7c7dfa87a7dde62d9f985e6e9ebebe7174921f638ed316d1476feed1e872f87effcdaf1ec3eedf08d97b2e395396e19ecbc42f3f3f5651d77bfb2c7698fa94ca1bc1b71dd3af577c197ab95f5e9d4fc62f9c66ce5387ac15dbb5831c5d0503f30888abcb03f157197689650c1a7c81cbaad9fe786351be5ba4ae7d3ceef502bfa6d1d362b5b8cef47dd9ee342a388b96f7a6bf3f341efddff8ae6e783a685d0c3c7ce993d5f7665e3aed2b94671b529499428515dd2f0f0b0343ebebebfe1e8916734393595f976f7d4ccf5d735be68e98575edbecf0cb5a20ba2f34b2b9a73ee12bd6d62540fecda76d96786debb634c0fecdaa6db27469b6d734b2b3a7cfed2ba381493be08d8282f8606c9a0bc403b54e25d4a1be97aeee6f9b563d9edcd6c908eb56c65addd46fabd8c95b536651f6fd9f95c59c7d1cfdcbf1beebaf8d628748c6e7b917c9d325bd25da29dbc5eb0b995f982b81b859e4ee676c58c133a5ebb1d2b2f5fda1f1bd74fec5cdb55763e1fb76014fab732ce4799cacc5d66ae543bd75e68fddac959a6d0fcca54f6b1969daf5d0b8b35cd2d5cd4ee4651f3e1274f348ba46bfd2bfae897fec5d963bde9f1e166d1347d0b7dfa854aee172b5525698be7adf50de74e9d6a7e2e689e73a74ee96c64ac2bba20aac65be453d3c3d575454f976d77f7eb846e3c998c7de2ea8bcbdba70cbe71ddedd00b8d76b533aedd47817cbeb8b2f9c60d898909e56b755d62e58d9b0ac56d349d388e985c9d183746afc68d55647e31313ebedfa1d0b8bed818be7c36b702713ebeb8bc7df2f8f6f7b56d34ed1e43bbfbe7293b7f285fa8bd15beebcfdd2efafb1163d673c7b4ef77d6fd77687e2a98af57f28ea3d7736c677e769f227ce3b6930f6bca7cd1ec160fec4f4c4c5e5c9973cd72aa7117ac9d971dbfec39faf2b9ed45e36cbfdbd629beb9d97915119bcf17e73bfe4ec81adbc7179fd5e73bde769491cfcebd9d9cbe6376db8bb279dcb656e27cf3f3c5156173b47aaca932f3d95c6e5bab9e3a764ed3e323fae46d7bb4b0586b1645f38aa192f4b1b75e25350aa921cdc26840cc5be5532f7f99d2da17291551b9fb2d37e6cd651df72df2311e3a7946f39ecf1ff589795226cf13a959e7ffd6bbfbda38572b71ca88cdca179a5f2b7cb95db65f9e9858be5c299bd3179b17135a97d8b85845f6b563a7ecbebe381ba3c8381b133a5e5f5b882fa78f8d4bf9e2dd585f7f2becf869ded0b1e6b55b362e962f9f2f972f4e6d9c3745ae7327c6cd53245fccfc1488f31d8365f3a47cf1be7c767f5fbbcd351bf8bd942736d56abe3cbefd42d78d1dd7151ad7ee93c6f9c6cd6a8fe11bab9d7cf2e4544e2e1b9fb57e31f3f3ed93d517ca6763e58929a248bed09cda9595b7c8fc5259f962e5e5f0f5bb73b5fb153d0e1b9f151be29b63881d4f9efd6c8cef3ab5db295f7b4c3e2baf7f10ed9c9a921a2f72db79e1dc8aac17ec597d4096ac6b27ab6f9094b10e65e4186465af5fd9f962bc78ea946d8af2b1b7eed6ed7b27f5f8fccff4f8fc694d8f0f37eff874fdf1bb5f2349fae897fea5b9cfdcc245fdae53104db47657e86a92a85eaf6bb956d30dbffa2e0dddfbebd2155b5e4ed670f4c837f495cffd996ebae7eedc2f467ae68b87f4cd2ffe4d54ac55b820aac6dda10fec9ad481d1f0edad734b2bcd6fa00700a0285e1003e8341e67fa13e7e572af7fe4cf6d53c7b97759b9dbae76ee40c2602afbba5af9d18f35f2ba9fb3cd97898deb25bb1645d6c1f2ad733bf9064dd9eb5776be5817befab7fac9a38fd9e628d3e3c3fae46d7b343d3ea285c595c65da2e182e8c9c59a0e343e77d4de459a1644eb49a2d54641f4e7dff94e8dbe67567ac5ce75b16adcf5f985dffb039d3b752ab3d099164e27a7a6f49b7ff8fbb63b574b05d1d4fed111ed1eae6adf155b7460748b4ed65675746945739796a3ef0a0500c08717c400ba81c79afec2f9f04bef10ed8550e1ca7d316ffb803c5c57d942eb535459790655d9eb5776be18adde21aa4651f4b6bddb75effe5768617145730b17f5c262adf94df4bbc747f4bec6172e49baecced0942d88aed46a7af54d3769e7ddef967e6eaf0d974c517432f03730edbbf3fe8f447d0193d556411400804ee14531806ee1f1a63f701ec276ecdaa54aa5629bbb26742753a75ed487c6b33a357ebfda6ceb123a9e8d32ff4e88290887d6cd72ef420ce542b6b2d7afec7c799224d199d3c5bf6cc8ba7defa4debe775207a6b7da2ea9f1454b9ffdd649cd2f5cb45d4d4992284912d5ea75adacae6ae7cc8cf6bceb5735f4f65b6d68535a14cdd26a315414440100fd8a17c600bae9d0a38ff078d3639c83b0b1f1095db1d5ff85b60000f85cbab8a40b8be76d73cba6c787353d3ea2fdd36392a4f9850b9945505792244a24adaed6555bada9323aaa5ff8955fd1d06fbcdf86760d055100000000e87363e313da327a454fef140500f4bf2449b4bc74a9d46268bbd28268bd5e57adf139a2d7df7187c6efba539ad963c39bbef2b93fd7d123476cb32469dfc183baf3fe0fdbe668953bdef4c6646c68c8b603000000000000405b924651b49e245a5d5dd5caeaaa26afbe5aafbeed360dcfbecb86373df3c5433af1dc0f6cb32469dfc1b769dfc1b7d9e66895bdd75d9bec1c19d1f691118d0d0d6988ffe308000000000000a004e9172b25e9172badae6ab956d381bbeed2e87fb823f32e51493ab3b0b06e7bc7f4f4baedc28e9f582b88da7600000000000000284b92246bdf385f4fb45a5fd52bafbe5a6fbdfd0e6d79ffaf4b193768fed5a7ff87feede8f725497b6f38a05ffbf87fb621f19244cb8ffd9586764eedfaafb60f000000000000004a55a92851a28aa4b367cf69726242dbea89aa7b5f6d239bae9c79a5eaababdafd9a57eb97ee7eb7c626276d48b4da534febf8f7bec71da2000000000000003aaf799768e3f344ebb555ddf59e7bb4fd6d37ab72c37e1b5eaae4d9799dfdc633faf2fffa22778802000000000000e8924a4549b27697a82ad2f163c734333ea19191115576b7f9f9a001c9b3f35afcd63fe8f097bfac7a52a7200a000000000000a0f32a8dcf0a6dfe57d24aada67ffbf18f75f5155768f8fca2aaaf7955e6678a169224aa3df5b45eface7774f8cb5fd6d2f2b286aa550aa200000000000000ba232d75aedd215a691645fff9fbdfd7b64a45e33f795e433bb64bdb5bffac5069eddbe497ffcf5775fc7bdfd5d7befa55ad268986aa5555aad5b5cf10dd3932a2ed23231a1b1ad2505915580000000000000070245abb73339154afd7b55aafab56afabb6baaadaeaaab65f75b55ef3e6376be4ca290dbfe90dd2cc1e9b22dbf113aafdd377557be1948efde33feaecf3ffaee1a1a1b59f6a75ad087bc79bde988c0d0dd95d01000000000000a074b6289a7ec952b3305aaf6b6a6646d7ecdbafad13e3d29e576a686646dab9431a1f97b68cac255a5e911617a517cf68f5f871e9c44f74f1fca27e72745ea78f1fd770b5da2c840e0d0da95aa9a85aadaa72f75b6ee45be60100000000000074cdfaa268a27a5257bd9e68b5be56105dadd755afd7b5656242dbaf9cd6ce3d7b34be7dbb464686556dbcf1beae442b2b352d9e3dab174f9cd0d91716b47cfebcaad5aa86aad5b542687548d56a45d54a55d5eada5bf4298802000000000000e83ab7289a2489ea49a2a49e68b55ed76a92de395a5792d4554fa444899246bc1a9f435aa954545145d58a54a95435345455b552d15065ad285aa95654ad541a718dcf2da5200a000000000000a017dca2a8a466513451f2f29da3c95a21b4be5639551a5d5145aaa4c5d0b5c2e7cb7782569ac5d0b5d897bfc4a9ad82e8fed1111db8628bf68d8e68f7f090e69696f542adaeb94bcb9a5f5ab1e100000000000000709924592b51a605d27ae3bfe91da1f5b4bf5114951a05cec6f7c357d36267a551244dfbd7bad7dad37fb752109d1eaeea815d933a30daf800538f855a5d0f9d7c510bb5baed020000000000c080b9e5befb9aff7efaf39f5fd7d7efd2b9f762deeebaa57a318f6e488ba1cd7f37b6d78aa32fb7a67d4e8953aaa859045dd7e714459b4d450ba2fb4747f4a9dd3b6cb3d742adae27cf2fe9b1b38bb60b1d72e8d1476c93663ff041dbd415e95c7ce3bbf3f4f50f327b0e7deb93b77e36870271000653d6e373b7f5d35cb2943dcfb2f3e571c72b73ec3273e1729d3a6fbd92f7fc05ed29fafcaf95f3b119ae43c0a79785ae7e16bb2eb1711ab08268d1f8589dcadb8fdce268733bc3baa2a7a708eaaada862cd3c3d5e862a81af1b74d8c6a7ab8d03068c3ec073ed8fcc1c6e33ec96ce73cb6bbff6676e8d147bc2f18807ed2efd769bfcf0f003aa59f1fff78fe07602378faf39f6ffea0776eb9efbecb7eb2e4c5da7e5f4c2b9a5f98d4780b7cfaa548de1f3726a718aaa277887e72f78e756f933f7c7e49b74f8cae8b91a4c7cf5cd0bd3bc69adb734b2b7af8e4997531b1def5918fe86b4f3ca1c5b3676d5794ac272c9bfdc942afff0f6eafc7df883ab1669dc85906fbbbd9adf9f5623decb1baba398f7e123a0fa1f641d3e97568377fbbfbbbcaccd54965cfb3ec7c79dcf1ca1c3b2b57e8b1cf172b4f7c284e39b1b6cf8a5903df7a59be7d43b10ac4e7f1cda3953c28cf46390f9d9a673b798bfc7ed858db9fca8b73fb7d8f13361e836b90eeb82b22765d62e336baa2c759343e56bb796fb9efbe75fbbac54b9b33ab2f55245f3f892e88de3e71851ed835d9dc3e7c7e499f3dfd92debf7d7c5df1f3b3a7cfe9f0f94b97b53f74f24c4b5fb474d7873ea4d75c7fbd9e7ce2093df7ed6fdbee5c83fcc7aed7c7deebf137a24eac592772b623eb896937e6d88bf5e8c598fd2eb426a1f641d3e97568377fbbfbbbcaccd54945e799179fd75f3677bc2263e7c566f587fa7cedb6cd6edb38db7728f037249427abcfb6dbed505b567bab5a3d6fe89c8d721e3a35cfb2f3da7c457ec743fbdafd52be769b13c5d9bbc042c58f32e3dc62505e7cd17e2b263e1493373f5b44ca6b8f91359e2b2fcef65b697c6c9c02b1a171f3d62e65635c5963fb72c5889d9fedb342eb67f386e6e9ce2324268f2b9433d49ea7d5fdba29ba206a0b9c6adc09fad8d9c5665f5a0cb5c55337b6a8bb3ef421fdfc8d374a92e6bef94d7ded8927b472e9920d0b8afd63e77bc2990afdf1cc8a93f9039c0ac5c4e42b2aefd8ed780ac4b613a7c0fab96caea26b62635cbef89022e3b612ebb231a9b2ce99ab68ce509c4c6c565c96bcf9b80e799efcdaf6d87361fb2c3b8e2fde972fb45f4cac55f458f2e214711c2a984f1dbe0e6c7b3b739327c6e60fb5973d6e2a2fcef65b79f1b63f65e352a1f890509e94cde78b0fc5b8edee7ea176dba716ce5ba7f88e69238a398eac98509faffd90e7f13e1467dbb264c587fa6cbbdd0ec585da70f9efae32d6c8c686e2f2b8e72226a78d51e0dc86f872e6f15df7a176dff836c695752d16c9e58b55467c51769e763b4bd63ad97c6e9b2f0eadf1153c6ef114f36c9cdd0ec5a56da1387962ddb6bc6d57565fcace256f1ea1f6acf9f8da62f9f6b5734edb94338f54569f2b362e158a8f5dbb32daecd8318acc2fab3de5f687feed93d7af8cb986f872fada62b5b36fb7447fb8e7959ecf01bd77c798debf7d5c8f9d5dd44327cf048ba192b42fe31be9631db8e9267df0c107f5dafdfb6d5769d23face94fda66e5c5b97f644331aebc7c658b9d9f6f5ea13879f25979fd2edfd845c68d19c3c71d374fde1c43f3b331e98f6db36c9e76d9f9b96dfdc2cec76ea7f2ce855d3737d6aea72f57da9ef28de1ae673b7ce3fb8e3b2fce9e5f5f8c2b2f5f2fc5cccd1eaf2fc6d79e75dedc714362c675dbdce3b071762c37d6cec1e673db5c36cee629c2ee5f647e597374b9fd6e4e9bcfc6badcf396175bb6aceb6923e9e471d873127b6eca9e939d87fbefb2c6c01afbfb18627fcf673d8f9345c53c1ef8c6b57176fe6e6cde716509cdc5b6f9c6f2c5c6f0e5f209ad4b3f287aecb3255c4b88638b1fbea248fa6fb760e38bf36dbbb2fa7cf97ce31661c7b3db565e7f37d83974625d3ac1cebb6cede66f77ff8de8960e7c3e68af5d5ee50c3830bac536498da2e8f47055f34b2b9a1eae7a8ba192b47b78c836b564c7d494def35bbfa5b7bfe7d76c572962ffd067c5859e4ca7dbbe3fc636b6938acc2f14e30ae56b57d9f962b9e3fad6c49535c7d0bad89cb39e279976bb137cf3b373eb04778c32c72973bd6c2ebb9df2b5fbda8a8acd9115e73bbfeeb66fed6d6c3fc99b9bef7843c7eacbe56b5344bed8717d71beed58be7c45c6edb4d0b8be39badc76775f5fbeac5c76dc6ef1cd7323da2cc711c3771d0dc2716f24ed9e8fbcfd43d7bbefdae895d0dc3a29b42e9de6ae7b3fac3de2f44b71e4e93effa21e3bbfd05c43edb1fae57cf49b415b97f47a8bb99e7c8572d72d8d3b6addfeacf5cccbd72fa20ba2276babb6496a7c66e842adaefda3235aa8d5f5f8990b36449234b7b46c9bdaf2e6dbdea1fb1e7c507b5eff7adbe595fe51757f62cc4616a662e362959d0fddb1d9cf5b7a7ced1ea3bb7fd6ef63689c507baf641d83cb3e06c5eca302d7556c5cac50beb2ae835e2b720ed079eeb9d888d7563aff8d3877d766398e5614793cc85b27fb585f24378a9d8b8d2c74fd84da07857bfcfcfef4375b1cc9ba73ac5777979539aecdd56ebe549a2794cf8e198adb08e7a3178aaccb208a598b98427e2a265fbf882e881ef57c2192fb99a19fdabda3f9f6795f51f4855add36b5adb6bcacda725ca1d57d01bf195ec8778b7d32cf1392cda757e7d7fe2e668d9fb687facb66d7246b5cf7b124ef71c53e06e5c5a3b84e9cb718b1e396ad57e37652d6f9d88cc78bde8b7d3cb0d75e56ac7daccf8ac5cbdc75b2ebbd99e51da37deccb8bdf0cecef4e19c73dcbdbe63bc277179aaf20e2c6f9f6e9143b5eabe3a6c7d46e9e3cbe9c764c5f4cca17d34fe7a3136c91d3771cbe63f4adcba071d7c0b76e45959dafd3a20ba27397d6171e1f3f73e1b2cf0c753f53f4f0f9a575f10babb575dbedfad6df7e558f7de6337afe5fffd576a124ee137efba4a4dfd82788fd3acf7e64cf6f2fce7391f18ac4b6a2e875ef3eb1e64976efd9f3163a7f659f373b5e68dcb2d9f1ba356e27a4f3ce3a1ff638fbe97863e6bf116c96e3e8847ebcee3623df1a0fcaf5e83bcea2cf4b36a3413bde8d6c23144042d2b977bb48d6c9352b2377ecbac4c6952554a08e39e6ac185b5c6d57b7d7c595772c65172fcbced70dd105d1f9a515cd397789de3631aa07766dbbec3343efdd31a607766dd3ed13a3cdb6b9a5151d3e1fffcdf0594efdf4dff5d7fff38f74e44bffdb7661c0849e20f2a4a9736ce1b91bca3e9f69be328f61d0aebb5e5c079dd0cfe7ad13d769993a35bf4ee5ed964eccbf17bf6b458ea395df23f7ef771e37a6c8bc0651ec6373d9719d14738d745bd9d7a13d46bb8de2b2d67096bb444b152ab4b8620b42a138bb1d2b94af4c65e62e23574c8e6eac4bbf19a4636d4556f1d277bda4ff0eed176aef47d1055135de229f9a1eaeae2b7aba6cbbbb5f3bbef3774fe991dffbeffad71ffcd076f595d013a5222f003aa99df9d97d14c8e78bdb8862d624c4b72eee762b39cb149a5fa7f9c6f3b55931319d121adbd7ee6beb85d0f9ede7ebaf9db9f9f285f8627c6d966f7eb1e386e2ec76ac503ecb1797b74f197ce3badb59e7d8b7afafad5f756aae65e7cb137b1c870a16cc7cd7806facbc9cb6df6e6363eac579f45d7fee76d6e355afd8b976826f5dda1dd7eeef5b631b136aebc4fc50dcd39fff7cf30eb4f4276db7713277acb9f15971365711be7cbe7153bef8acbe76e6e6d36ebeb2cf47ca17ef9317e76bb7dbb17c63f9f2a7b1be7ebb2e9de29b6b2b7cfbdbed58be1cbefcf2ccdf6d4b15c9d74f2a77bfe5c6c4366671df221fe3a1936734eff9fcd158777de8437ae56b5faba79e7842fffcecb3b63b57d61f46df1fdfbc273db1710a8c6df72b922f866fcc941dc3179b1733ebfc5f55dffaa562e35cf6894d682e45f3c50ae5f2e5f1cd25c49737b45f5e5e5fae54abeb128ab57132b1befe58be31b3f265ad4ba82fd49eb273c85abf59cff56cb753be769bcfe58bb339add83805c6b6fb15c9a712af0379e667f385e696d76e153d6f7979acd8781b67fbadbc78db9ff25d576e9f3dde56f972bb6cbf326262da7df9e4396f31b93aadcc31cbcc5554ded859fd79e7cbb2f1a1381588cd9a9f2b2b2eabcfb2f372c5ecdf0e77ecacb1ca8e8b51645d7cb1362646e8bce5b5bb6c8ccbc667c5e6c95b6bdf58bee3b071ae32e242e316e1cb69d91805e2e489b571bef9e6ad37d06da12213c2b2d62cab0f70152e88aa7177e803bb26756074c47635cd2dad34bf81be1deffc8ddfd0537ffdd7bab4b4fe334901df139c98be9056f64177706ed06d5c73e8275c8f00006c5e14f08acb5ab3ac3ec055e82df3a9855a5d0f9f3ca3874e9e697cd3fc92166a75cd2dade8f13317f4d0c9337af8e499b68ba192f4d5bffc4b8aa100006020510c050060f3a27857ae7e7e7b36fa4f4b778802fd20f422b1d5b7c184f2a1b7382fe805ae3bf45aab7fcb000040ff730b7714435b132a7eb29e884541141b9afddca0542b2f1e2980f4178a01e8251e0f0000000060f3a2200a0000000000006060542facaeda3600000000000000d894aa3f5e5cd4898b17f552ada6d5849b45010000000000006c4eab49a2cadeebaea50a0a0000000000006020546d03000000000000006c561444010000000000000c0c0aa2000000000000000606055100000000000000038382280000000000008081414114000000000000c0c0a0200a0000000000006060501005000000000000303028880200000000000018181444010000000000000c0c0aa2000000000000000606055100000000000000038382280000000000008081414114000000000000c0c0a0200a0000000000006060501005000000000000303028880200000000000018186d174487272674e5c1b7697862c27601000000000000405f69bb20baf5aaabb4ed753fa7abef7c274551000000000000007daded82e84b3ffa915efceef73432314e5114000000000000405f6bbb202a492f7ef77b144501000000000000f4bd520aa2a2280a000000000000600328ad202a8aa200000000000000fa5ca9055149aa9d5f6cfe9b8228000000000000807e526a4174dbeb5ea72b0fdeac95f38b7ae1c837b4f4fcf33604000000000000007aa6b48228c55000000000000000fdae948228c550000000000000001b41db05518aa100000000000000368ab60ba2179f7f5e4bcf9fa4180a000000000000a0ef55f65e776d621b0100000000000060336afb0e5100000000000000d82828880200000000000018181444010000000000000c0c0aa2000000000000000606055100000000000000038382280000000000008081414114000000000000c0c0a0200a0000000000006060501005000000000000303028880200000000000018181444010000000000000c8cff0f8154efdf935d53ee0000000049454e44ae426082, 10656, 'Screenshot 2026-05-01 200945.png', '2026-05-01 20:57:44'),
(12, 9, 5, 'document', 'qq', 'qqw', '', 0x89504e470d0a1a0a0000000d49484452000005440000006e0806000000ef7319a0000000017352474200aece1ce90000000467414d410000b18f0bfc6105000000097048597300000ec300000ec301c76fa8640000293549444154785eeddd6f905c5779e7f15ff7ccc8a399d14842e3916d348008d84e24b9f863426c64076c67f13ae031a90a9822868275c82b5c5b6c42b9ca4ed5562dd42621cb0bb2af12f2a74c5c3695b816855d0a5225e36061968404f08c2843609544825863094bb2461acdf4f4dd17d3b77de6d139f79edb7dfbcf4c7f3f5553d63de7b9cf39f7dc3b3ddd8f6f7757f65e776d22000000000000001800955bdff75e0aa2000000000000000642853b44010000000000000c8aaa6d0000000000000080cd8a82280000000000008081414114000000000000c0c0a0200a000000000000a02f254952e827060551000000000000007dc35be04c242589544f94d4eb4aea75a99eacb5b961be7d8dcadeebae4d768e8c68fbc888c686863454a9d81800000000000000e898b48099ac6da8def8efc8d898c6a7a6347ed5551addb64d4343c3cd3b3ceb9256576b5a7ae9252d3effbc164f9dd2ca850b52a5b21653a928ad74561a35cfd52451e58e37bd31191b1a6a74010000000000004077a405d0f47ece7a9228a927dafeca6bf48ad75fab2d6363d29e6b34343323eddc218d8f4b5b46d6829757a4c545e9c5335a3d7e5c3af1532d5fb8a09ffdf30f75f6273f55a55a51b55108ade8e50269e5eeb7dc18be7f14000000000000003ac02d862649a27a9268e2ca695d75c3015577edd2f09bde20cdecb1bb653b7e42b57ffaaeeaa74febf967e774fe8505552b1555d2bb452b150aa200000000d0efc6c627b465f48ae6dbfd0000f0499244cb4b977461f1bcedea3b6e31b45e4f544feabae60d6fd4e4cc8c860ede54bc106a1d3fa1da916feaa5e3c7f5d3ef7e47d54a55d52a77880200000040df1b1b9fd0155b476d33000041972e2e955a149d1e1fd6f4f888f64f8fe9caf1617d7fe1a20e1f3b67c3a2ad2f86d655ddb245afbae9666db9f6751afae55ba4b2fe07609268f5ef9ed6f20f7fa47ffbe633aa2f2fab5aadb65710dd3f3aa203576cd1bed111ed1e1ed2dcd2b25ea8d535776959f34b2b361c0000000050d08e5dbbb8331400504892243a73fab46d2e6cfff4567df2b6f09d9a0b8b2b7af2d84b7a7c3e7e2c5b0cad8c8c68efadb76acb8d6f56e586fd36bc14c9b3f35afef63fead8d7bfae6465a5b582e8f470550fec9ad481d1c607987a2cd4ea7ae8e48b5aa8d56d170000000020d2cea929dbd434f5994febd4c77fc736a345539ff9b424f5644dd3b15dbd980750367b6dfbae6b3726af3fe58beb855e3e6ee479f1d429db146d7a7c581f7beb553a30bdb5d9f6f8fccf34bf704192b47b7c44bf30bd55b7ef9d94241d3e764e5f983fad85c55a33dec71643ebf544af7dc73b34fa4bbfd8b162682a79765e4bfff7eff5ffbef6b5e205d1fda323fad4ee1db6d96ba156d793e797f4d8d945dbd555871e7da4f9efd90f7c705d9f4c7fca17d78e748cb2f3765237d625d6465c3fb48ef38d7e54f6755976be2c797f07637473bee83dfb1c6010cefba1471f1988e3ec07a1c713ce4158a820dacf2fc237aa7e59d37e99c7a0e33cb42f760df30aa2aed89cddd26ff371b55310fde377bf46d3e3239a5bb8a8dde3c392a48f7ee95f6cd8bac2e9c2e28a1e7ef244665134498ba149a27abdae6bdef0064dfee25b34f4f65b6d68cbce9d3aadc9a95db65992b4fad4d775eeefff4155db91657ab81a5d0c5523feb689514d0f171aa6eb663ff0c1e64fbf3af4e82397bd38e9b48db02ed8987a713d03c83668bf97651f6fd9f97ac92d560dcaf3806e9fbbcd74bd948d7529cebe009ffacca79b3fbe7600e847a73efe3bcd1f14177aec6fd57fbb6d8fa6c74774f8d839fdee93276c77d374a350fa47df7a5e8fcfff4cd3e3237adf7e7f2152e9dda16951b45ed7f895d3da36f3aab5cf0c2dd1335ffc1bdbd434f4cbb76872e655c50aa20fec5abb0d3675f8fcd2baedd4e367d66e9f95f3f6fa18e99343fbd3ae417a420f0080c5df41f45adef33afbdc2f14978a8d8b91e6f0fd7e84c6f1b5f58a5db77e9a5b51e939d8a8f30700a017a64afee894fdd35b75607aabe6162eea8fbe75d27637a57786a69f2ffae4b1b39a5bb8a8dbf74e36df467f99c6dda1499268354974f50d3768f8e04de57d8192a4e3cffd40478f1cd1d123dfb05d6b2a150d1dbc29fe2df3b74f5cb1aeb079f8fc923e7bfa25bd7ffbb8eedd31d66cffece9733a7cfed265ed0f9d3c93fb454b594f48bba5537368376fbbfbb76bd0c747b9f2ce675e3fd00b655f9765e76b57de7cf2fa379ab28fa7ec7cbd54f6b1d8e296cdeb1bcfd766fb52be985859e3c88c153bbf18edeeef2a3357b7e4cd39af7f10f9de321f7a8b66e86da731f1f2f4a76c9ccb378ecbd77feae3bf73596c68ec18b1b9f2e28acecfc6a8cdb854e87cc5b2e3d9e3b1796dbcda3c6f364605e252a1b1b28e23962fafcbf65b31f1a1187b0c695b6a2a50dc0ab567891d532dc6ba6c4ccacdeb532457aa68ce505c9ed835293bcee5c6f962a69cebc2b72eadbc653e7dabfcc34f9ed0fcc2c5669b9cb7ccdbcf174ddf2abf16bb570b8b2b97bdbd3efdecd07a9268b55ed7b6abafd635b7deaae1d977ad8bb38e1ef9868e3ff7431d7fee396d9fdaa53dd75fa799ebafd7f6a9a9cbde167ff4c837f495cffd5973fbcefb3fa27d07dfb62e26155d10b5054e35ee047decec62b32f2d86dae2a91b9ba5c8931ffb64589efd6262acbc39d89cb171a9507c48284fcae6f3c5db9856145d170562db895320368f3b779bd7e6cbeb4fb51a27131b5a575f7b2f8f4326362b2e8b1dcf4af316395679f2fa628a88cd1713177b2c87029f9be66bcfca938a1d3756917c79fda9bcb82263ca934f9e354edb6c6c6c3e79626d9ced4fd9b85428dec7773db86cbf6f4cbbbf2fc695c6175dbf5836974ace6773d97e2b263e6f8d5dbef573e5b5a76c7f51369f327286e6d4aaf4ba0ce54dfb6d9b3cb1695f56be22f272b8ebe63bef76bfbc75f6f5bb6cbe18a1b9f8f8c6f7cdcfe6b2edeeb6cd69f755605c0562e5190fe18268e8c5b19c17dc592f946d9bdd0ec565b5d9ed941dc36d73dbedd8317cfbdab9a46dca892b32bfb2db5c79fd79dcfd43ff7663ed762a6df7b5b9edb6cd6ea77ced596da1b9dbb822ecbe76db95d5972a7abca1f6acf9f8da62f8c60ce5f2c5baed59fbdb36379765c775d93c215971b6cf6e17e15b135f3e5f9cdb6ef7f5b585e6e7db27c497ab9582e817ef7dbd0e1f3bb7eeee50b7206a8ba1a9b4289af67df44bc7d67d9668f3b343eb75d5ea75bdee1defd0d6fff84e69c6ff0df6e74e9dd6573ef7a73afedc0f9a6d9353533ad738a6c9a929bdefc14f68726a57e3aed06774f4c81127c39a7d070feae67beebeac781afd96f92b3d9f037aef8e31bd7ffbb81e3bbba8874e9e09164325695fc637d217953e114e7fdc76972fa61dee9333fb84d065e3da19dfeeefe6b47943e3fae658a6d87163cf5b285fbb7ce3bb63db716d7fcac6cd7a5e0c84e2dcf656153d8ed8f9b96d9de28ee56edbf654deb1badb593145d87c65ad5f9163096dbb6d59795c31e31691972f767e366e36b0ce326386f8f2b9edaebc6370b76d9c65e3dc36978d0be52b5bcc78b6dfddc7b75fccfac5f2e54adb5be15b679bcb8e9575bc31f3b37d59f962c51c4711be7c6e7bfaeff4c7b6b5236fffa2fd76bb1deebae489390731eb6caf0b3736661eed88995f51873cbf23365f68dc2ca15c785956b12196ef85b37d815e947db16eb75d597d65b0f97dc7ebdb4e85da5379f9d2fed8b85e0acdcd27ab2f6563ec762ff9ce47bbe7c21e9fddb6f2fa3ba1c8f166cdcfb77eeeb6db9ffeb83176bfb2f9e667e7d68ad87cb1c7179baf17d2b7babf90f1a54807a6c774607aab0e1f3ba785c5152d2cae343f3f747a7c44471b77954e8fbf5c076cde8999244a9244236363da32369e590cfd93dffe848e3ff703ed3b7850ef7df013fa2f7ff1a7facd3ffc7dbdf7c14f68dfc1833a77ea94bef07b7fa073a74e6be6faeb74e7fd1fd69df77f4493ceff447cef839fd09df77ff8b262a88a14440f8c6eb14d52a3283a3d5cd5fcd24ae6e785ee1e1eb24d2db34fa4ec7627f89e34fb9eacf9e2ba2134ae6f8e652a326e28c615ca5786ac9cbe717dc7106273fbf2b9db3139436c4e57deb8295f5c19732b9b9db7d5ade3b0f368655c9ba315bd1ad79595af95f9b942b9f3f2f9c675b7edd836ce0ae5b37c71be317d71edf0e5eea6b28e439e5c76bb0cede4b4fbdaed6e6a75ecd0f567afd5594fb1ca6e17151a3bcf21cf1da369bb5ac8d70da1b9d975ee954ecdcfe6b342e3a21cb12fbc0749bf141480226ca130f4bb1d6aef343b3f7457bafedd3a0757368a982f2c863ff2f2f0b1737af8c913ebee207d7cfeb43efaa5639a5fb8a8f985b5ef15da3fbdfe5de689a47ae3dbe527764d497bae59d7effa93dffe84d478cbfb9df77f5833d75fd7ec4b8b9f37dd73f7baa2a824ed3bf836ed3b78b324e9a67bee5eb79f155d103d595bb54d52e33343176a75ed1f1dd142adbeee0b955c734bcbb629e8d026f85078f4bfb25ee8f55abbc7112b1da71b63f5834e9f5fbb96a1750db5b7ca8edbae76f3757a9d07016b78b9cdb2269be1388a3e3e1c0a144353597d838ee7cff039e5f99c3a6bcaf966e2bcd83c3657bbf962b985826e8fbd19d873d6eedad95cede6eb8432e76773b59b2f95e6292bdf20e9c4f91834271b05d1f45be45db7ef9d6c7eb6a82b7d7bfc6ee7ced0a6a4718f68e36df313d75cada199191b2535be14498d8266e8f33f25e9e67b669b45d1e3cf3db7ae7de6faeb74f33db3ebe2ade882e851cf1722b99f19faa9dd3b9a6f9ff715455fa8d56d53905b78f13df1b54ff8baf9a4af57e36e0676edfa71fd62e6e75e9379b1fd2ee6783782328fa3c8f92d73dc544c9e4e8c5ba698f91559e77e1773bc9d7028a770b411d8b56b77fdcabeaeecdcdac95544d9c7d10badccf750c635dd4abeb2cd46bc6dbe97f29e3f63f328fbc5bd7bf751de9d48b6c0600b91695b5e9e4ef08d59f65a6d46659fb756f2655d579d62e717334f9f568eb7159dc8b999d9f3d1a9f3b219b97777ee9fdeaa3f7ef75eddbbffe5b79b7fecadbbf5befdaf087f8b7cce5da6492225f5bab66e9b9476eeb0dd92d42c6ece5c7fbdedba4c1a73fcb91fae6bbff3feffb46edb27ba203a7769fd1d9e8f9fb970d96786ba9f297af8fcd2baf885d5f0e70f14913e11edd5933e3b6eb7c7dfa87a7dde62d9f985e6e9ebebe7174921f638ed316d1476feed1e872f87effcdaf1ec3eedf08d97b2e395396e19ecbc42f3f3f5651d77bfb2c7698fa94ca1bc1b71dd3af577c197ab95f5e9d4fc62f9c66ce5387ac15dbb5831c5d0503f30888abcb03f157197689650c1a7c81cbaad9fe786351be5ba4ae7d3ceef502bfa6d1d362b5b8cef47dd9ee342a388b96f7a6bf3f341efddff8ae6e783a685d0c3c7ce993d5f7665e3aed2b94671b529499428515dd2f0f0b0343ebebebfe1e8916734393595f976f7d4ccf5d735be68e98575edbecf0cb5a20ba2f34b2b9a73ee12bd6d62540fecda76d96786debb634c0fecdaa6db27469b6d734b2b3a7cfed2ba381493be08d8282f8606c9a0bc403b54e25d4a1be97aeee6f9b563d9edcd6c908eb56c65addd46fabd8c95b536651f6fd9f95c59c7d1cfdcbf1beebaf8d628748c6e7b917c9d325bd25da29dbc5eb0b995f982b81b859e4ee676c58c133a5ebb1d2b2f5fda1f1bd74fec5cdb55763e1fb76014fab732ce4799cacc5d66ae543bd75e68fddac959a6d0fcca54f6b1969daf5d0b8b35cd2d5cd4ee4651f3e1274f348ba46bfd2bfae897fec5d963bde9f1e166d1347d0b7dfa854aee172b5525698be7adf50de74e9d6a7e2e689e73a74ee96c64ac2bba20aac65be453d3c3d575454f976d77f7eb846e3c998c7de2ea8bcbdba70cbe71ddedd00b8d76b533aedd47817cbeb8b2f9c60d898909e56b755d62e58d9b0ac56d349d388e985c9d183746afc68d55647e31313ebedfa1d0b8bed818be7c36b702713ebeb8bc7df2f8f6f7b56d34ed1e43bbfbe7293b7f285fa8bd15beebcfdd2efafb1163d673c7b4ef77d6fd77687e2a98af57f28ea3d7736c677e769f227ce3b6930f6bca7cd1ec160fec4f4c4c5e5c9973cd72aa7117ac9d971dbfec39faf2b9ed45e36cbfdbd629beb9d97915119bcf17e73bfe4ec81adbc7179fd5e73bde769491cfcebd9d9cbe6376db8bb279dcb656e27cf3f3c5156173b47aaca932f3d95c6e5bab9e3a764ed3e323fae46d7bb4b0586b1645f38aa192f4b1b75e25350aa921cdc26840cc5be5532f7f99d2da17291551b9fb2d37e6cd651df72df2311e3a7946f39ecf1ff589795226cf13a959e7ffd6bbfbda38572b71ca88cdca179a5f2b7cb95db65f9e9858be5c299bd3179b17135a97d8b85845f6b563a7ecbebe381ba3c8381b133a5e5f5b882fa78f8d4bf9e2dd585f7f2becf869ded0b1e6b55b362e962f9f2f972f4e6d9c3745ae7327c6cd53245fccfc1488f31d8365f3a47cf1be7c767f5fbbcd351bf8bd942736d56abe3cbefd42d78d1dd7151ad7ee93c6f9c6cd6a8fe11bab9d7cf2e4544e2e1b9fb57e31f3f3ed93d517ca6763e58929a248bed09cda9595b7c8fc5259f962e5e5f0f5bb73b5fb153d0e1b9f151be29b63881d4f9efd6c8cef3ab5db295f7b4c3e2baf7f10ed9c9a921a2f72db79e1dc8aac17ec597d4096ac6b27ab6f9094b10e65e4186465af5fd9f962bc78ea946d8af2b1b7eed6ed7b27f5f8fccff4f8fc694d8f0f37eff874fdf1bb5f2349fae897fea5b9cfdcc245fdae53104db47657e86a92a85eaf6bb956d30dbffa2e0dddfbebd2155b5e4ed670f4c837f495cffd996ebae7eedc2f467ae68b87f4cd2ffe4d54ac55b820aac6dda10fec9ad481d1f0edad734b2bcd6fa00700a0285e1003e8341e67fa13e7e572af7fe4cf6d53c7b97759b9dbae76ee40c2602afbba5af9d18f35f2ba9fb3cd97898deb25bb1645d6c1f2ad733bf9064dd9eb5776be5817befab7fac9a38fd9e628d3e3c3fae46d7b343d3ea285c595c65da2e182e8c9c59a0e343e77d4de459a1644eb49a2d54641f4e7dff94e8dbe67567ac5ce75b16adcf5f985dffb039d3b752ab3d099164e27a7a6f49b7ff8fbb63b574b05d1d4fed111ed1eae6adf155b7460748b4ed65675746945739796a3ef0a0500c08717c400ba81c79afec2f9f04bef10ed8550e1ca7d316ffb803c5c57d942eb535459790655d9eb5776be18adde21aa4651f4b6bddb75effe5768617145730b17f5c262adf94df4bbc747f4bec6172e49baecced0942d88aed46a7af54d3769e7ddef967e6eaf0d974c517432f03730edbbf3fe8f447d0193d556411400804ee14531806ee1f1a63f701ec276ecdaa54aa5629bbb26742753a75ed487c6b33a357ebfda6ceb123a9e8d32ff4e88290887d6cd72ef420ce542b6b2d7afec7c799224d199d3c5bf6cc8ba7defa4debe775207a6b7da2ea9f1454b9ffdd649cd2f5cb45d4d4992284912d5ea75adacae6ae7cc8cf6bceb5735f4f65b6d68535a14cdd26a315414440100fd8a17c600bae9d0a38ff078d3639c83b0b1f1095db1d5ff85b60000f85cbab8a40b8be76d73cba6c787353d3ea2fdd36392a4f9850b9945505792244a24adaed6555bada9323aaa5ff8955fd1d06fbcdf86760d055100000000e87363e313da327a454fef140500f4bf2449b4bc74a9d46268bbd28268bd5e57adf139a2d7df7187c6efba539ad963c39bbef2b93fd7d123476cb32469dfc183baf3fe0fdbe668953bdef4c6646c68c8b603000000000000405b924651b49e245a5d5dd5caeaaa26afbe5aafbeed360dcfbecb86373df3c5433af1dc0f6cb32469dfc1b769dfc1b7d9e66895bdd75d9bec1c19d1f691118d0d0d6988ffe308000000000000a004e9172b25e9172badae6ab956d381bbeed2e87fb823f32e51493ab3b0b06e7bc7f4f4baedc28e9f582b88da7600000000000000284b92246bdf385f4fb45a5fd52bafbe5a6fbdfd0e6d79ffaf4b193768fed5a7ff87feede8f725497b6f38a05ffbf87fb621f19244cb8ffd9586764eedfaafb60f000000000000004a55a92851a28aa4b367cf69726242dbea89aa7b5f6d239bae9c79a5eaababdafd9a57eb97ee7eb7c626276d48b4da534febf8f7bec71da2000000000000003aaf799768e3f344ebb555ddf59e7bb4fd6d37ab72c37e1b5eaae4d9799dfdc633faf2fffa22778802000000000000e8924a4549b27697a82ad2f163c734333ea19191115576b7f9f9a001c9b3f35afcd63fe8f097bfac7a52a7200a000000000000a0f32a8dcf0a6dfe57d24aada67ffbf18f75f5155768f8fca2aaaf7955e6678a169224aa3df5b45eface7774f8cb5fd6d2f2b286aa550aa200000000000000ba232d75aedd215a691645fff9fbdfd7b64a45e33f795e433bb64bdb5bffac5069eddbe497ffcf5775fc7bdfd5d7befa55ad268986aa5555aad5b5cf10dd3932a2ed23231a1b1ad2505915580000000000000070245abb73339154afd7b55aafab56afabb6baaadaeaaab65f75b55ef3e6376be4ca290dbfe90dd2cc1e9b22dbf113aafdd377557be1948efde33feaecf3ffaee1a1a1b59f6a75ad087bc79bde988c0d0dd95d01000000000000a074b6289a7ec952b3305aaf6b6a6646d7ecdbafad13e3d29e576a686646dab9431a1f97b68cac255a5e911617a517cf68f5f871e9c44f74f1fca27e72745ea78f1fd770b5da2c840e0d0da95aa9a85aadaa72f75b6ee45be60100000000000074cdfaa268a27a5257bd9e68b5be56105dadd755afd7b5656242dbaf9cd6ce3d7b34be7dbb464686556dbcf1beae442b2b352d9e3dab174f9cd0d91716b47cfebcaad5aa86aad5b542687548d56a45d54a55d5eada5bf4298802000000000000e83ab7289a2489ea49a2a49e68b55ed76a92de395a5792d4554fa444899246bc1a9f435aa954545145d58a54a95435345455b552d15065ad285aa95654ad541a718dcf2da5200a000000000000a017dca2a8a466513451f2f29da3c95a21b4be5639551a5d5145aaa4c5d0b5c2e7cb7782569ac5d0b5d897bfc4a9ad82e8fed1111db8628bf68d8e68f7f090e69696f542adaeb94bcb9a5f5ab1e100000000000000709924592b51a605d27ae3bfe91da1f5b4bf5114951a05cec6f7c357d36267a551244dfbd7bad7dad37fb752109d1eaeea815d933a30daf800538f855a5d0f9d7c510bb5baed020000000000c080b9e5befb9aff7efaf39f5fd7d7efd2b9f762deeebaa57a318f6e488ba1cd7f37b6d78aa32fb7a67d4e8953aaa859045dd7e714459b4d450ba2fb4747f4a9dd3b6cb3d742adae27cf2fe9b1b38bb60b1d72e8d1476c93663ff041dbd415e95c7ce3bbf3f4f50f327b0e7deb93b77e36870271000653d6e373b7f5d35cb2943dcfb2f3e571c72b73ec3273e1729d3a6fbd92f7fc05ed29fafcaf95f3b119ae43c0a79785ae7e16bb2eb1711ab08268d1f8589dcadb8fdce268733bc3baa2a7a708eaaada862cd3c3d5e862a81af1b74d8c6a7ab8d03068c3ec073ed8fcc1c6e33ec96ce73cb6bbff6676e8d147bc2f18807ed2efd769bfcf0f003aa59f1fff78fe07602378faf39f6ffea0776eb9efbecb7eb2e4c5da7e5f4c2b9a5f98d4780b7cfaa548de1f3726a718aaa277887e72f78e756f933f7c7e49b74f8cae8b91a4c7cf5cd0bd3bc69adb734b2b7af8e4997531b1def5918fe86b4f3ca1c5b3676d5794ac272c9bfdc942afff0f6eafc7df883ab1669dc85906fbbbd9adf9f5623decb1baba398f7e123a0fa1f641d3e97568377fbbfbbbcaccd54965cfb3ec7c79dcf1ca1c3b2b57e8b1cf172b4f7c284e39b1b6cf8a5903df7a59be7d43b10ac4e7f1cda3953c28cf46390f9d9a673b798bfc7ed858db9fca8b73fb7d8f13361e836b90eeb82b22765d62e336baa2c759343e56bb796fb9efbe75fbbac54b9b33ab2f55245f3f892e88de3e71851ed835d9dc3e7c7e499f3dfd92debf7d7c5df1f3b3a7cfe9f0f94b97b53f74f24c4b5fb474d7873ea4d75c7fbd9e7ce2093df7ed6fdbee5c83fcc7aed7c7deebf137a24eac592772b623eb896937e6d88bf5e8c598fd2eb426a1f641d3e97568377fbbfbbbcaccd54945e799179fd75f3677bc2263e7c566f587fa7cedb6cd6edb38db7728f037249427abcfb6dbed505b567bab5a3d6fe89c8d721e3a35cfb2f3da7c457ec743fbdafd52be769b13c5d9bbc042c58f32e3dc62505e7cd17e2b263e1493373f5b44ca6b8f91359e2b2fcef65b697c6c9c02b1a171f3d62e65635c5963fb72c5889d9fedb342eb67f386e6e9ce2324268f2b9433d49ea7d5fdba29ba206a0b9c6adc09fad8d9c5665f5a0cb5c55337b6a8bb3ef421fdfc8d374a92e6bef94d7ded8927b472e9920d0b8afd63e77bc2990afdf1cc8a93f9039c0ac5c4e42b2aefd8ed780ac4b613a7c0fab96caea26b62635cbef89022e3b612ebb231a9b2ce99ab68ce509c4c6c565c96bcf9b80e799efcdaf6d87361fb2c3b8e2fde972fb45f4cac55f458f2e214711c2a984f1dbe0e6c7b3b739327c6e60fb5973d6e2a2fcef65b79f1b63f65e352a1f890509e94cde78b0fc5b8edee7ea176dba716ce5ba7f88e69238a398eac98509faffd90e7f13e1467dbb264c587fa6cbbdd0ec585da70f9efae32d6c8c686e2f2b8e72226a78d51e0dc86f872e6f15df7a176dff836c695752d16c9e58b55467c51769e763b4bd63ad97c6e9b2f0eadf1153c6ef114f36c9cdd0ec5a56da1387962ddb6bc6d57565fcace256f1ea1f6acf9f8da62f9f6b5734edb94338f54569f2b362e158a8f5dbb32daecd8318acc2fab3de5f687feed93d7af8cb986f872fada62b5b36fb7447fb8e7959ecf01bd77c798debf7d5c8f9d5dd44327cf048ba192b42fe31be9631db8e9267df0c107f5dafdfb6d5769d23face94fda66e5c5b97f644331aebc7c658b9d9f6f5ea13879f25979fd2edfd845c68d19c3c71d374fde1c43f3b331e98f6db36c9e76d9f9b96dfdc2cec76ea7f2ce855d3737d6aea72f57da9ef28de1ae673b7ce3fb8e3b2fce9e5f5f8c2b2f5f2fc5cccd1eaf2fc6d79e75dedc714362c675dbdce3b071762c37d6cec1e673db5c36cee629c2ee5f647e597374b9fd6e4e9bcfc6badcf396175bb6aceb6923e9e471d873127b6eca9e939d87fbefb2c6c01afbfb18627fcf673d8f9345c53c1ef8c6b57176fe6e6cde716509cdc5b6f9c6f2c5c6f0e5f209ad4b3f287aecb3255c4b88638b1fbea248fa6fb760e38bf36dbbb2fa7cf97ce31661c7b3db565e7f37d83974625d3ac1cebb6cede66f77ff8de8960e7c3e68af5d5ee50c3830bac536498da2e8f47055f34b2b9a1eae7a8ba192b47b78c836b564c7d494def35bbfa5b7bfe7d76c572962ffd067c5859e4ca7dbbe3fc636b6938acc2f14e30ae56b57d9f962b9e3fad6c49535c7d0bad89cb39e279976bb137cf3b373eb04778c32c72973bd6c2ebb9df2b5fbda8a8acd9115e73bbfeeb66fed6d6c3fc99b9bef7843c7eacbe56b5344bed8717d71beed58be7c45c6edb4d0b8be39badc76775f5fbeac5c76dc6ef1cd7323da2cc711c3771d0dc2716f24ed9e8fbcfd43d7bbefdae895d0dc3a29b42e9de6ae7b3fac3de2f44b71e4e93effa21e3bbfd05c43edb1fae57cf49b415b97f47a8bb99e7c8572d72d8d3b6addfeacf5cccbd72fa20ba2276babb6496a7c66e842adaefda3235aa8d5f5f8990b36449234b7b46c9bdaf2e6dbdea1fb1e7c507b5eff7adbe595fe51757f62cc4616a662e362959d0fddb1d9cf5b7a7ced1ea3bb7fd6ef63689c507baf641d83cb3e06c5eca302d7556c5cac50beb2ae835e2b720ed079eeb9d888d7563aff8d3877d766398e5614793cc85b27fb585f24378a9d8b8d2c74fd84da07857bfcfcfef4375b1cc9ba73ac5777979539aecdd56ebe549a2794cf8e198adb08e7a3178aaccb208a598b98427e2a265fbf882e881ef57c2192fb99a19fdabda3f9f6795f51f4855add36b5adb6bcacda725ca1d57d01bf195ec8778b7d32cf1392cda757e7d7fe2e668d9fb687facb66d7246b5cf7b124ef71c53e06e5c5a3b84e9cb718b1e396ad57e37652d6f9d88cc78bde8b7d3cb0d75e56ac7daccf8ac5cbdc75b2ebbd99e51da37deccb8bdf0cecef4e19c73dcbdbe63bc277179aaf20e2c6f9f6e9143b5eabe3a6c7d46e9e3cbe9c764c5f4cca17d34fe7a3136c91d3771cbe63f4adcba071d7c0b76e45959dafd3a20ba27397d6171e1f3f73e1b2cf0c753f53f4f0f9a575f10babb575dbedfad6df7e558f7de6337afe5fffd576a124ee137efba4a4dfd82788fd3acf7e64cf6f2fce7391f18ac4b6a2e875ef3eb1e64976efd9f3163a7f659f373b5e68dcb2d9f1ba356e27a4f3ce3a1ff638fbe97863e6bf116c96e3e8847ebcee3623df1a0fcaf5e83bcea2cf4b36a3413bde8d6c23144042d2b977bb48d6c9352b2377ecbac4c6952554a08e39e6ac185b5c6d57b7d7c595772c65172fcbced70dd105d1f9a515cd397789de3631aa07766dbbec3343efdd31a607766dd3ed13a3cdb6b9a5151d3e1fffcdf0594efdf4dff5d7fff38f74e44bffdb7661c0849e20f2a4a9736ce1b91bca3e9f69be328f61d0aebb5e5c079dd0cfe7ad13d769993a35bf4ee5ed964eccbf17bf6b458ea395df23f7ef771e37a6c8bc0651ec6373d9719d14738d745bd9d7a13d46bb8de2b2d67096bb444b152ab4b8620b42a138bb1d2b94af4c65e62e23574c8e6eac4bbf19a4636d4556f1d277bda4ff0eed176aef47d1055135de229f9a1eaeae2b7aba6cbbbb5f3bbef3774fe991dffbeffad71ffcd076f595d013a5222f003aa99df9d97d14c8e78bdb8862d624c4b72eee762b39cb149a5fa7f9c6f3b55931319d121adbd7ee6beb85d0f9ede7ebaf9db9f9f285f8627c6d966f7eb1e386e2ec76ac503ecb1797b74f197ce3badb59e7d8b7afafad5f756aae65e7cb137b1c870a16cc7cd7806facbc9cb6df6e6363eac579f45d7fee76d6e355afd8b976826f5dda1dd7eeef5b631b136aebc4fc50dcd39fff7cf30eb4f4276db7713277acb9f15971365711be7cbe7153bef8acbe76e6e6d36ebeb2cf47ca17ef9317e76bb7dbb17c63f9f2a7b1be7ebb2e9de29b6b2b7cfbdbed58be1cbefcf2ccdf6d4b15c9d74f2a77bfe5c6c4366671df221fe3a1936734eff9fcd158777de8437ae56b5faba79e7842fffcecb3b63b57d61f46df1fdfbc273db1710a8c6df72b922f866fcc941dc3179b1733ebfc5f55dffaa562e35cf6894d682e45f3c50ae5f2e5f1cd25c49737b45f5e5e5fae54abeb128ab57132b1befe58be31b3f265ad4ba82fd49eb273c85abf59cff56cb753be769bcfe58bb339add83805c6b6fb15c9a712af0379e667f385e696d76e153d6f7979acd8781b67fbadbc78db9ff25d576e9f3dde56f972bb6cbf326262da7df9e4396f31b93aadcc31cbcc5554ded859fd79e7cbb2f1a1381588cd9a9f2b2b2eabcfb2f372c5ecdf0e77ecacb1ca8e8b51645d7cb1362646e8bce5b5bb6c8ccbc667c5e6c95b6bdf58bee3b071ae32e242e316e1cb69d91805e2e489b571bef9e6ad37d06da12213c2b2d62cab0f70152e88aa7177e803bb26756074c47635cd2dad34bf81be1deffc8ddfd0537ffdd7bab4b4fe334901df139c98be9056f64177706ed06d5c73e8275c8f00006c5e14f08acb5ab3ac3ec055e82df3a9855a5d0f9f3ca3874e9e697cd3fc92166a75cd2dade8f13317f4d0c9337af8e499b68ba192f4d5bffc4b8aa100006020510c050060f3a27857ae7e7e7b36fa4f4b778802fd20f422b1d5b7c184f2a1b7382fe805ae3bf45aab7fcb000040ff730b7714435b132a7eb29e884541141b9afddca0542b2f1e2980f4178a01e8251e0f0000000060f3a2200a0000000000006060542facaeda3600000000000000d894aa3f5e5cd4898b17f552ada6d5849b45010000000000006c4eab49a2cadeebaea50a0a0000000000006020546d03000000000000006c561444010000000000000c0c0aa2000000000000000606055100000000000000038382280000000000008081414114000000000000c0c0a0200a0000000000006060501005000000000000303028880200000000000018181444010000000000000c0c0aa2000000000000000606055100000000000000038382280000000000008081414114000000000000c0c0a0200a0000000000006060501005000000000000303028880200000000000018186d174487272674e5c1b7697862c27601000000000000405f69bb20baf5aaabb4ed753fa7abef7c274551000000000000007daded82e84b3ffa915efceef73432314e5114000000000000405f6bbb202a492f7ef77b144501000000000000f4bd520aa2a2280a000000000000600328ad202a8aa200000000000000fa5ca9055149aa9d5f6cfe9b8228000000000000807e526a4174dbeb5ea72b0fdeac95f38b7ae1c837b4f4fcf33604000000000000007aa6b48228c55000000000000000fdae948228c550000000000000001b41db05518aa100000000000000368ab60ba2179f7f5e4bcf9fa4180a000000000000a0ef55f65e776d621b0100000000000060336afb0e5100000000000000d82828880200000000000018181444010000000000000c0c0aa2000000000000000606055100000000000000038382280000000000008081414114000000000000c0c0a0200a0000000000006060501005000000000000303028880200000000000018181444010000000000000c8cff0f8154efdf935d53ee0000000049454e44ae426082, 10656, 'qq.png', '2026-05-01 21:13:03'),
(15, 9, 9, 'document', 'harbina', 'kahla', 'uploads/resources/1777860559_L3_final_project_report.pdf', NULL, NULL, '', '2026-05-04 03:09:19'),
(16, 9, 10, 'document', 'hhh', '', 'uploads/resources/1777931263_L3_final_project_report.pdf', NULL, NULL, '', '2026-05-04 22:47:43');

-- --------------------------------------------------------

--
-- Structure de la table `secretaries`
--

CREATE TABLE `secretaries` (
  `user_id` int(11) NOT NULL,
  `employee_id` varchar(50) NOT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL,
  `position` varchar(100) DEFAULT 'Secretary',
  `status` enum('Active','Inactive','On Leave') NOT NULL DEFAULT 'Active',
  `qualification` varchar(255) DEFAULT NULL,
  `salary` decimal(10,2) DEFAULT NULL,
  `address` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `secretaries`
--

INSERT INTO `secretaries` (`user_id`, `employee_id`, `gender`, `hire_date`, `department`, `position`, `status`, `qualification`, `salary`, `address`) VALUES
(27, 'assasa', 'Female', '2026-04-12', 'Academic Affairs', 'Secretary', 'Active', NULL, NULL, 'مسجد الرسالة: المدينة الجديدة تاسيف'),
(28, 'bassstop1', NULL, '2026-04-28', 'Registration', 'Secretary', 'Active', NULL, NULL, NULL);

--
-- Déclencheurs `secretaries`
--
DELIMITER $$
CREATE TRIGGER `before_secretary_insert_logic` BEFORE INSERT ON `secretaries` FOR EACH ROW BEGIN
    IF NEW.`hire_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Secretary hire date cannot be in the future!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `staff`
--

CREATE TABLE `staff` (
  `employee_id` varchar(50) NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL,
  `position` varchar(100) DEFAULT 'Secretary',
  `status` enum('Active','Inactive','On Leave') NOT NULL DEFAULT 'Active',
  `qualification` varchar(255) DEFAULT NULL,
  `salary` decimal(10,2) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `staff`
--

INSERT INTO `staff` (`employee_id`, `full_name`, `email`, `phone`, `hire_date`, `department`, `position`, `status`, `qualification`, `salary`, `address`, `notes`, `gender`) VALUES
('dssd', 'mohamed moundas', '', '1234567891', '2026-03-03', NULL, 'Marketing', 'Active', 'ds', 26.00, 'dc', 'c', 'Male');

--
-- Déclencheurs `staff`
--
DELIMITER $$
CREATE TRIGGER `before_staff_insert_logic` BEFORE INSERT ON `staff` FOR EACH ROW BEGIN
    IF NEW.`hire_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Staff hire date cannot be in the future!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `students`
--

CREATE TABLE `students` (
  `user_id` int(11) NOT NULL,
  `class_name` varchar(50) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `student_id` varchar(50) DEFAULT NULL,
  `language` varchar(50) DEFAULT NULL,
  `level` varchar(50) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` varchar(20) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `status` enum('active','inactive','graduated') DEFAULT 'active',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `students`
--

INSERT INTO `students` (`user_id`, `class_name`, `parent_id`, `student_id`, `language`, `level`, `date_of_birth`, `gender`, `phone`, `address`, `status`, `updated_at`) VALUES
(3, '', 14, 'ziad', NULL, NULL, '2005-11-05', 'Male', NULL, NULL, 'active', '2026-04-26 12:12:16'),
(4, '', 31, 'Saadi', NULL, NULL, '2005-11-11', 'Male', '0765325753', 'jdfskjdfjesklc,dkksls,dkks', 'inactive', '2026-05-02 13:19:41'),
(33, NULL, 14, 'batman1', NULL, NULL, '2026-05-02', 'Male', '1234554321', '', 'active', '2026-05-03 07:53:01');

--
-- Déclencheurs `students`
--
DELIMITER $$
CREATE TRIGGER `before_student_insert_logic` BEFORE INSERT ON `students` FOR EACH ROW BEGIN
    -- Check 1: Date of Birth cannot be in the future
    IF NEW.`date_of_birth` >= CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Date of birth cannot be today or in the future!';
    END IF;

    -- Check 2: Reasonable past limit for Date of Birth
    IF NEW.`date_of_birth` < '1950-01-01' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Date of birth is too old (Invalid)!';
    END IF;

    -- Check 3: Phone length check
    IF NEW.`phone` IS NOT NULL AND LENGTH(NEW.`phone`) < 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Student phone number is too short!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `submissions`
--

CREATE TABLE `submissions` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `assignment_id` int(11) DEFAULT NULL,
  `teacher_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `file_url` varchar(500) NOT NULL,
  `file_data` longblob DEFAULT NULL,
  `file_size` int(11) DEFAULT NULL,
  `file_mime` varchar(100) DEFAULT NULL,
  `grade` int(11) DEFAULT NULL,
  `submitted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `submissions`
--

INSERT INTO `submissions` (`id`, `student_id`, `assignment_id`, `teacher_id`, `class_id`, `type`, `title`, `description`, `file_url`, `file_data`, `file_size`, `file_mime`, `grade`, `submitted_at`) VALUES
(1, 3, 7, 9, 9, 'assignment', 'Assignment Submission', NULL, '../../uploads/submissions/1777748354_Prgrm.jpg', NULL, NULL, NULL, 98, '2026-05-02 19:59:14'),
(2, 4, 7, 9, 9, 'assignment', 'Assignment Submission', NULL, '../../uploads/submissions/1777750189_Android_OS.pdf', NULL, NULL, NULL, 34, '2026-05-02 20:29:49'),
(3, 3, NULL, 9, 9, 'assignment', 'Assignment Submission', NULL, '../../uploads/submissions/1777758992_Negan_school_managment.rar', NULL, NULL, NULL, 99, '2026-05-02 22:56:32'),
(4, 33, 10, 9, 10, 'assignment', 'Assignment Submission', NULL, '../../uploads/submissions/1777935387_plan.txt', NULL, NULL, NULL, 30, '2026-05-04 23:56:27');

--
-- Déclencheurs `submissions`
--
DELIMITER $$
CREATE TRIGGER `before_submission_insert_logic` BEFORE INSERT ON `submissions` FOR EACH ROW BEGIN
    -- Ensure a file URL is provided for the submission
    IF NEW.`file_url` IS NULL OR NEW.`file_url` = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Submission file is required!';
    END IF;

    -- Block future submission dates
    IF NEW.`submitted_at` > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Submission time cannot be in the future!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `teachers`
--

CREATE TABLE `teachers` (
  `user_id` int(11) NOT NULL,
  `subject` varchar(100) DEFAULT NULL,
  `teacher_id` varchar(50) DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `language` varchar(50) DEFAULT NULL,
  `qualification` varchar(255) DEFAULT NULL,
  `experience_years` int(11) DEFAULT 0,
  `specialization` varchar(255) DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `status` enum('active','inactive','on-leave') DEFAULT 'active',
  `salary` decimal(10,2) DEFAULT 0.00,
  `employee_id` varchar(50) DEFAULT NULL,
  `position` varchar(100) DEFAULT NULL,
  `bio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `teachers`
--

INSERT INTO `teachers` (`user_id`, `subject`, `teacher_id`, `gender`, `language`, `qualification`, `experience_years`, `specialization`, `hire_date`, `status`, `salary`, `employee_id`, `position`, `bio`) VALUES
(9, NULL, 'adil', NULL, 'Arabic', 'شس', 20, 'literature', '2005-11-10', 'active', 20.00, NULL, NULL, 'ndnvk,cls,ckddld'),
(10, NULL, 'sifou', NULL, 'French', '', 7, 'literature', '2018-11-24', 'active', 32.00, NULL, NULL, 'kdvlkdlskdepdp'),
(30, NULL, 'dsffds', NULL, 'German', 'xzcxz', 5, 'cxzcxz', '2026-04-29', 'active', 0.00, NULL, NULL, NULL);

--
-- Déclencheurs `teachers`
--
DELIMITER $$
CREATE TRIGGER `before_teacher_insert_logic` BEFORE INSERT ON `teachers` FOR EACH ROW BEGIN
    -- Check 1: Hire date cannot be in the future
    IF NEW.`hire_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Teacher hire date cannot be in the future!';
    END IF;

    -- Check 2: Experience years must be realistic relative to age (Optional but professional)
    IF NEW.`experience_years` > 50 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Experience years exceeds realistic limit (50 years)!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `role` enum('manager','teacher','student','parent','secretary','staff') NOT NULL DEFAULT 'student',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `full_name`, `email`, `role`, `created_at`, `phone`, `address`, `hire_date`, `department`) VALUES
(2, 'manager', '$2y$10$kvDA/lnbKH6NBQUZo87Sge9kCAdGp8cc3g9LurcHMrgz1cXvud8Z2', 'booo3lam', 'manager@schoolhub.com', 'manager', '2026-04-14 10:13:30', '0540543460', '', NULL, NULL),
(3, 'ziad', '$2y$10$GT1kFQtL6LtYUd8gwG/44uSPXD7i0mY9Zp.yVEVoMwsQuMTqyGmXy', 'Ziad Messaoudene', 'messziad5@gmail.com', 'student', '2026-04-24 18:21:37', '0765325752', 'Ouled Aissa\nLekite', NULL, NULL),
(4, 'Saadi', '$2y$10$Pd6vCiF0elM0Evvugv9fQu/W7lMxgYeblx.BVUPkQlAXnv2oaaKR2', 'Saadi Abderahime', 'saddi@gmail.com', 'student', '2026-04-24 18:43:05', '0765325757', 'jdfskjdfjesklc,dkksls,dkks', NULL, NULL),
(9, 'adil', '$2y$10$RRrihdYhl5thshxDOaXMZe6IHaxPVHxT3tfTdsVj1Y7QXUFLC6cIq', 'Adil Retima', 'adil@gmail.com', 'teacher', '2026-04-24 19:02:47', '0633463235', 'jddksklgls;lskdlf', NULL, NULL),
(10, 'sifou', '$2y$10$ydSSh/U25KO8kQm3bDt5MeeTCu/FFnYumro7qkV4FO2ALNWALjQfu', 'sifou mettai', 'sifou@gmail.com', 'teacher', '2026-04-24 19:41:39', '0633463236', 'jfkkflsdpdozpd;', NULL, NULL),
(14, 'mounir', '$2y$10$SoQXc6aaRTc7O.v5NxfU6eZil6CTA4kMnj5RMjNborhX9COLQI8aG', 'mounir messaoudene', 'mounir@gmail.com', 'parent', '2026-04-24 22:02:30', '0654356740', 'kdjfldsdlekfld', NULL, NULL),
(27, 'assasa', '$2y$10$EBBON2cH7eCrpllM2c5x/u0uGF.S56UW/Qi9gC4aJnoyIW0l05tRG', 'مسجد الرسالة', 'arrisalamosquee@gmail.com', 'secretary', '2026-04-26 12:56:47', '0540543460', 'مسجد الرسالة: المدينة الجديدة تاسيف', NULL, NULL),
(28, 'bassstop1', '$2y$10$OyCBjD0kOlVr7QIiNapyQeJldkkmFTxMRjgZBN64ktVP.NXzfcJ3O', 'bassstop', 'bassstop@gmail.com', 'secretary', '2026-05-01 17:00:08', '1234567890', 'zz', NULL, NULL),
(30, 'dsffds', '$2y$10$ISSvL.ZgW.vAeUtVsT.uGO1EgCBhtYl5JmYV.Xb2W8BPaX7Oa.qwq', 'cxz', 'cxz@gmail.com', 'teacher', '2026-05-01 18:04:41', '1234567890', 'cxzcxz', NULL, NULL),
(31, 'koko', '$2y$10$teSkatpcNcBQ/OQDBaCj.OAj54.blZZR0JfdLmtONFRaS83cCxId6', 'koko', 'koko2@gmail.com', 'parent', '2026-05-01 18:14:38', '0987654321', 'sas', NULL, NULL),
(33, 'batman1', '$2y$10$VXI3W/Xs22aswLjTVRV7HeoHCKSZZvB2jBa6/F9G6UCGpTRLrGQy2', 'batman', 'batman@gmai.com', 'student', '2026-05-03 07:53:01', '1234554321', '', NULL, NULL);

--
-- Déclencheurs `users`
--
DELIMITER $$
CREATE TRIGGER `before_insert_check_phone` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    IF NEW.phone IS NOT NULL AND LENGTH(NEW.phone) != 10 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Phone number must be exactly 10 digits';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_update_check_phone` BEFORE UPDATE ON `users` FOR EACH ROW BEGIN
    IF NEW.phone IS NOT NULL AND LENGTH(NEW.phone) != 10 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Phone number must be exactly 10 digits';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_user_insert_logic` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    -- Block future hire dates
    IF NEW.`hire_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Hire date cannot be in the future!';
    END IF;
    
    -- Final check for email format
    IF NEW.`email` NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Invalid email format!';
    END IF;
END
$$
DELIMITER ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `assignments`
--
ALTER TABLE `assignments`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`id`),
  ADD KEY `class_id` (`class_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Index pour la table `attendances`
--
ALTER TABLE `attendances`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `classes`
--
ALTER TABLE `classes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`),
  ADD KEY `idx_room_status` (`room`,`status`);

--
-- Index pour la table `class_schedules`
--
ALTER TABLE `class_schedules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_class_day_time` (`class_id`,`day`,`time`),
  ADD KEY `class_id` (`class_id`),
  ADD KEY `idx_day_time` (`day`,`time`);

--
-- Index pour la table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_pair` (`participant1_id`,`participant2_id`);

--
-- Index pour la table `enrollments`
--
ALTER TABLE `enrollments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `class_id` (`class_id`);

--
-- Index pour la table `expenses`
--
ALTER TABLE `expenses`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `grades`
--
ALTER TABLE `grades`
  ADD PRIMARY KEY (`id`),
  ADD KEY `class_id` (`class_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Index pour la table `manager_settings`
--
ALTER TABLE `manager_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Index pour la table `meetings`
--
ALTER TABLE `meetings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `with_type` (`with_type`,`with_id`);

--
-- Index pour la table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `conversation_id` (`conversation_id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Index pour la table `parents`
--
ALTER TABLE `parents`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `parent_id` (`parent_id`);

--
-- Index pour la table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `resources`
--
ALTER TABLE `resources`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `secretaries`
--
ALTER TABLE `secretaries`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `employee_id` (`employee_id`);

--
-- Index pour la table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`employee_id`);

--
-- Index pour la table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `student_id` (`student_id`),
  ADD KEY `parent_id` (`parent_id`);

--
-- Index pour la table `submissions`
--
ALTER TABLE `submissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `assignment_id` (`assignment_id`);

--
-- Index pour la table `teachers`
--
ALTER TABLE `teachers`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `teacher_id` (`teacher_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `assignments`
--
ALTER TABLE `assignments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT pour la table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT pour la table `attendances`
--
ALTER TABLE `attendances`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `classes`
--
ALTER TABLE `classes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT pour la table `class_schedules`
--
ALTER TABLE `class_schedules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT pour la table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT pour la table `enrollments`
--
ALTER TABLE `enrollments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT pour la table `expenses`
--
ALTER TABLE `expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT pour la table `grades`
--
ALTER TABLE `grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT pour la table `manager_settings`
--
ALTER TABLE `manager_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT pour la table `meetings`
--
ALTER TABLE `meetings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT pour la table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT pour la table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT pour la table `resources`
--
ALTER TABLE `resources`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT pour la table `submissions`
--
ALTER TABLE `submissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `classes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `classes`
--
ALTER TABLE `classes`
  ADD CONSTRAINT `classes_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `class_schedules`
--
ALTER TABLE `class_schedules`
  ADD CONSTRAINT `class_schedules_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `classes` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `enrollments`
--
ALTER TABLE `enrollments`
  ADD CONSTRAINT `enrollments_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `enrollments_ibfk_2` FOREIGN KEY (`class_id`) REFERENCES `classes` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `grades`
--
ALTER TABLE `grades`
  ADD CONSTRAINT `grades_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `classes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `grades_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `manager_settings`
--
ALTER TABLE `manager_settings`
  ADD CONSTRAINT `manager_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_3` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `parents`
--
ALTER TABLE `parents`
  ADD CONSTRAINT `parents_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `secretaries`
--
ALTER TABLE `secretaries`
  ADD CONSTRAINT `secretaries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `students_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `students_ibfk_2` FOREIGN KEY (`parent_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `students_ibfk_3` FOREIGN KEY (`parent_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `students_ibfk_4` FOREIGN KEY (`parent_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `students_ibfk_5` FOREIGN KEY (`parent_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `submissions`
--
ALTER TABLE `submissions`
  ADD CONSTRAINT `submissions_ibfk_1` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `teachers`
--
ALTER TABLE `teachers`
  ADD CONSTRAINT `teachers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

DELIMITER $$
--
-- Évènements
--
CREATE DEFINER=`root`@`localhost` EVENT `auto_complete_meetings` ON SCHEDULE EVERY 1 HOUR STARTS '2026-04-25 18:21:13' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    UPDATE meetings 
    SET status = 'completed' 
    WHERE status IN ('accepted', 'scheduled', 'pending')
    AND CONCAT(date, ' ', time) < NOW();
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
