DROP DATABASE IF EXISTS QUANLYKHOAHOC;
CREATE DATABASE QUANLYKHOAHOC CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE QUANLYKHOAHOC;

-- Thay thế NVARCHAR bằng VARCHAR và NVARCHAR(MAX) bằng TEXT/LONGTEXT
-- Thay thế DATETIME bằng DATETIME
-- Thay thế GETDATE() bằng NOW()

-- --------------------------------------------------------
-- TABLE DEFINITIONS
-- --------------------------------------------------------

CREATE TABLE GiaoVien (
    MaGiaoVien          VARCHAR(50)     NOT NULL PRIMARY KEY,  -- TeacherXXX
    HoTen               VARCHAR(200)    NOT NULL,
    DuongDanAnhDaiDien  VARCHAR(1000)   NULL,
    Email               VARCHAR(200)    NOT NULL UNIQUE,
    DienThoai           VARCHAR(50)     NULL,
    GioiThieu           TEXT            NULL,                  -- Thay NVARCHAR(MAX) bằng TEXT
    NgayTao             DATETIME        NOT NULL DEFAULT NOW() -- Thay GETDATE() bằng NOW()
);

CREATE TABLE KhoaHoc (
    MaKhoaHoc           VARCHAR(50)     NOT NULL PRIMARY KEY,  -- CourseXXX
    MonHoc              VARCHAR(100)    NOT NULL,
    TieuDe              VARCHAR(300)    NOT NULL,
    DuongDanAnhKhoaHoc  VARCHAR(1000)   NULL,
    MoTa                LONGTEXT        NOT NULL,              -- Thay NVARCHAR(MAX) bằng LONGTEXT
    GiaKhoaHoc          DECIMAL(10,2)   NOT NULL,
    ThoiHan             INT             NOT NULL DEFAULT 150,  -- đơn vị: ngày
    MaGiaoVien          VARCHAR(50)     NOT NULL,              -- FK → GiaoVien
    NgayCapNhat         DATETIME        NOT NULL DEFAULT NOW(),
    CONSTRAINT FK_KhoaHoc_GiaoVien
      FOREIGN KEY(MaGiaoVien) REFERENCES GiaoVien(MaGiaoVien)
      ON UPDATE CASCADE ON DELETE NO ACTION
);

CREATE TABLE MucTieuKhoaHoc (
    MaKhoaHoc           VARCHAR(50)     NOT NULL,
    ThuTu               INT             NOT NULL,
    NoiDung             VARCHAR(1000)   NOT NULL,
    PRIMARY KEY (MaKhoaHoc, ThuTu),
    FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE YeuCauKhoaHoc (
    MaKhoaHoc           VARCHAR(50)     NOT NULL,
    ThuTu               INT             NOT NULL,
    NoiDung             VARCHAR(1000)   NOT NULL,
    PRIMARY KEY (MaKhoaHoc, ThuTu),
    FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE BaiHoc (
    MaBaiHoc            VARCHAR(30)     NOT NULL PRIMARY KEY,  -- CourseXXX_YY
    MaKhoaHoc           VARCHAR(50)     NOT NULL,              -- FK → KhoaHoc
    ThuTu               INT             NOT NULL,
    TieuDe              VARCHAR(200)    NULL,
    LinkVideo           VARCHAR(1000)   NOT NULL,
    NgayTao             DATETIME        NOT NULL DEFAULT NOW(),
    CONSTRAINT FK_BaiHoc_KhoaHoc
      FOREIGN KEY(MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc)
      ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE HocSinh (
    MaHocSinh        VARCHAR(50)      NOT NULL PRIMARY KEY,  -- StudentXXX
    HoTen            VARCHAR(200)     NOT NULL,
    PassHash         TEXT             NOT NULL,              -- Thay VARCHAR(MAX) bằng TEXT
    DuongDanAnhDaiDien VARCHAR(1000)  NULL,
    Email            VARCHAR(200)     NOT NULL UNIQUE,
    DienThoai        VARCHAR(50)      NULL,
    NgaySinh         DATE             NULL,                  -- DATE giữ nguyên
    GioiTinh         VARCHAR(10)      NULL,
    DiaChi           VARCHAR(500)     NULL,
    NgayDangKy       DATETIME         NOT NULL DEFAULT NOW()
);

CREATE TABLE GioHang (
    MaGioHang       VARCHAR(30)     NOT NULL PRIMARY KEY,  -- VD: Cart_Student001
    MaHocSinh       VARCHAR(50)     NOT NULL UNIQUE,       -- UNIQUE đảm bảo mỗi học sinh chỉ có 1 giỏ hàng
    NgayTao         DATETIME        NOT NULL DEFAULT NOW(),
    CONSTRAINT FK_GioHang_HocSinh
        FOREIGN KEY (MaHocSinh) REFERENCES HocSinh(MaHocSinh)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ChiTietGioHang (
    MaGioHang       VARCHAR(30)     NOT NULL,
    MaKhoaHoc       VARCHAR(50)     NOT NULL,
    NgayThem        DATETIME        NOT NULL DEFAULT NOW(),
    PRIMARY KEY (MaGioHang, MaKhoaHoc),
    FOREIGN KEY (MaGioHang) REFERENCES GioHang(MaGioHang)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE KhoaHoc_HocSinh (
    MaKhoaHoc       VARCHAR(50)     NOT NULL,
    MaHocSinh       VARCHAR(50)     NOT NULL,
    NgayDangKy      DATETIME        NOT NULL DEFAULT NOW(),
    PRIMARY KEY (MaKhoaHoc, MaHocSinh),
    CONSTRAINT FK_KhoaHocHocSinh_KhoaHoc
        FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_KhoaHocHocSinh_HocSinh
        FOREIGN KEY (MaHocSinh) REFERENCES HocSinh(MaHocSinh)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Admin (
    MaAdmin             VARCHAR(50)     NOT NULL PRIMARY KEY,
    HoTen               VARCHAR(200)    NOT NULL,
    PassHash            TEXT            NOT NULL,
    DuongDanAnhDaiDien  VARCHAR(1000)   NULL,
    Email               VARCHAR(200)    NOT NULL UNIQUE,
    DienThoai           VARCHAR(50)     NULL
);

-- --------------------------------------------------------
-- TRIGGER DEFINITIONS (Sử dụng cú pháp MySQL: BEFORE INSERT)
-- --------------------------------------------------------

DELIMITER $$

-- 1. TRIGGER cho GiaoVien (TeacherXXX)
DROP TRIGGER IF EXISTS trg_GiaoVien_BeforeInsert;
DELIMITER $$

CREATE TRIGGER trg_GiaoVien_BeforeInsert
BEFORE INSERT ON GiaoVien
FOR EACH ROW
BEGIN
    IF NEW.MaGiaoVien IS NULL OR NEW.MaGiaoVien = '' OR NEW.MaGiaoVien = 'temp' THEN
        SELECT IFNULL(MAX(0 + SUBSTRING(MaGiaoVien, 8)), 0)
        INTO @max_id
        FROM GiaoVien
        WHERE MaGiaoVien REGEXP '^Teacher[0-9]+$';

        SET NEW.MaGiaoVien = CONCAT('Teacher', @max_id + 1);
    END IF;

    SET NEW.NgayTao = IFNULL(NEW.NgayTao, NOW());
END$$


-- 2. TRIGGER cho HocSinh (StudentXXX)
DROP TRIGGER IF EXISTS trg_HocSinh_BeforeInsert;
DELIMITER $$

CREATE TRIGGER trg_HocSinh_BeforeInsert
BEFORE INSERT ON HocSinh
FOR EACH ROW
BEGIN
    IF NEW.MaHocSinh IS NULL OR NEW.MaHocSinh = '' OR NEW.MaHocSinh = 'temp' THEN
        SELECT IFNULL(MAX(0 + SUBSTRING(MaHocSinh, 8)), 0)
        INTO @max_id
        FROM HocSinh
        WHERE MaHocSinh REGEXP '^Student[0-9]+$';

        SET NEW.MaHocSinh = CONCAT('Student', @max_id + 1);
    END IF;

    SET NEW.NgayDangKy = IFNULL(NEW.NgayDangKy, NOW());
END$$

-- 3. TRIGGER AFTER INSERT cho HocSinh để tạo Giỏ hàng (Cart_StudentXXX)
-- MySQL không cho phép INSTEAD OF INSERT, nên việc tạo giỏ hàng phụ thuộc phải là AFTER INSERT
DROP TRIGGER IF EXISTS trg_HocSinh_AfterInsert;
DELIMITER $$

CREATE TRIGGER trg_HocSinh_AfterInsert
AFTER INSERT ON HocSinh
FOR EACH ROW
BEGIN
    INSERT INTO GioHang (MaGioHang, MaHocSinh, NgayTao)
    VALUES (CONCAT('Cart_', NEW.MaHocSinh), NEW.MaHocSinh, NOW());
END$$


-- 4. TRIGGER cho KhoaHoc (CourseXXX)
DROP TRIGGER IF EXISTS trg_KhoaHoc_BeforeInsert;
DELIMITER $$

CREATE TRIGGER trg_KhoaHoc_BeforeInsert
BEFORE INSERT ON KhoaHoc
FOR EACH ROW
BEGIN
    IF NEW.MaKhoaHoc IS NULL OR NEW.MaKhoaHoc = '' OR NEW.MaKhoaHoc = 'temp' THEN
        
        SELECT IFNULL(MAX(0 + SUBSTRING(MaKhoaHoc, 7)), 0)
        INTO @max_id
        FROM KhoaHoc
        WHERE MaKhoaHoc REGEXP '^Course[0-9]+$';

        SET NEW.MaKhoaHoc = CONCAT('Course', @max_id + 1);
    END IF;

    SET NEW.NgayCapNhat = IFNULL(NEW.NgayCapNhat, NOW());
END$$


-- 5. TRIGGER cho BaiHoc (CourseXXX_YY)
DROP TRIGGER IF EXISTS trg_BaiHoc_BeforeInsert;
DELIMITER $$

CREATE TRIGGER trg_BaiHoc_BeforeInsert
BEFORE INSERT ON BaiHoc
FOR EACH ROW
BEGIN
    IF NEW.MaBaiHoc IS NULL OR NEW.MaBaiHoc = '' OR NEW.MaBaiHoc = 'temp' THEN
        SET @thu_tu_padded = LPAD(CAST(NEW.ThuTu AS CHAR), 2, '0');
        SET NEW.MaBaiHoc = CONCAT(NEW.MaKhoaHoc, '_', @thu_tu_padded);
    END IF;

    SET NEW.NgayTao = IFNULL(NEW.NgayTao, NOW());
END$$
DELIMITER ;


-- --------------------------------------------------------
-- INSERT DATA
-- --------------------------------------------------------

-- INSERT GIAOVIEN (Sử dụng TRIGGER để tự động sinh MaGiaoVien)
-- Nếu không cung cấp MaGiaoVien, nó sẽ tự động sinh Teacher1, Teacher2,...
INSERT INTO GiaoVien (MaGiaoVien, HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES
('Teacher1', N'Nguyễn Văn A', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'nguyenvana748@example.com', '0901234567', N'Hơn 10 năm kinh nghiệm trong nghề'),
('Teacher2', N'Trần Thị B', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'tranthib982@example.com', '0912345678', N'Giáo viên nhiệt tình trẻ tuổi'),
('Teacher3', N'Lê Văn C', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'levanc351@example.com', '0923456789', N'Giáo viên nhiệt tình trẻ tuổi'),
('Teacher4', N'Phạm Thị D', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'phamthid623@example.com', '0934567890', N'Giáo viên nhiệt tình trẻ tuổi'),
('Teacher5', N'Hoàng Văn E', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'hoangvane107@example.com', '0945678901', NULL),
('Teacher6', N'Vũ Thị F', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'vuthif462@example.com', '0956789012', NULL),
('Teacher7', N'Đặng Văn G', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'dangvang715@example.com', '0967890123', NULL),
('Teacher8', N'Bùi Thị H', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'buithih289@example.com', '0978901234', NULL),
('Teacher9', N'Ngô Văn I', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'nvani390@example.com', '0989012345', NULL),
('Teacher10', N'Đỗ Thị K', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'dothik178@example.com', '0990123456', NULL);


-- INSERT KHOAHOC (Sử dụng TRIGGER để tự động sinh MaKhoaHoc)
-- Dữ liệu này sẽ tự động sinh từ Course1, Course2,...
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES
(N'Toán', N'Toán 10 cơ bản', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khóa học toán lớp 10 cơ bản dành cho học sinh phổ thông.', 500000, 150, 'Teacher1'),    -- Course1
(N'Hóa học', N'Hóa học 11 nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Nâng cao kiến thức hóa học lớp 11 với các chuyên đề nâng cao.', 650000, 140, 'Teacher1'),   -- Course2
(N'Vật lý', N'Vật lý 10 - Sách bài tập', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Hướng dẫn giải bài tập Vật lý 10 theo chương trình chuẩn.', 400000, 150, 'Teacher2'),    -- Course3
(N'Ngữ văn', N'Ngữ văn 12 ôn thi THPT', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tổng hợp kiến thức ngữ văn lớp 12 để ôn thi THPT.', 700000, 140, 'Teacher3'),       -- Course4
(N'Địa lý', N'Địa lý 12 luyện đề', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Luyện tập các đề thi thử địa lý lớp 12 theo cấu trúc đề thi mới.', 550000, 140, 'Teacher4'),      -- Course5
(N'Sinh học', N'Sinh học 10 cơ bản', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tìm hiểu cấu trúc tế bào, sinh học phân tử và di truyền học cơ bản.', 500000, 150, 'Teacher4'), -- Course6
(N'Tin học', N'Tin học 11 lập trình Pascal', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khóa học lập trình Pascal cơ bản dành cho học sinh lớp 11.', 600000, 150, 'Teacher5'),     -- Course7
(N'Tiếng Anh', N'Tiếng Anh 10 nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Trọn bộ kiến thức nâng cao tiếng Anh lớp 10, phát âm và giao tiếp.', 750000, 150, 'Teacher5'),  -- Course8
(N'Giáo dục công dân', N'GDCD 12 trọng tâm', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tổng hợp kiến thức GDCD 12 trọng tâm thi THPT.', 400000, 140, 'Teacher6'),       -- Course9
(N'Toán', N'Toán 11 hình học nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Chuyên đề hình học không gian lớp 11 nâng cao.', 600000, 150, 'Teacher6'),    -- Course10
(N'Hóa học', N'Hóa học 12 luyện thi đại học', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Các chuyên đề trọng điểm hóa học 12, luyện thi THPT quốc gia.', 700000, 150, 'Teacher7'),  -- Course11
(N'Vật lý', N'Vật lý 12 lý thuyết trọng tâm', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Các phần lý thuyết quan trọng Vật lý lớp 12, ôn luyện thi.', 500000, 140, 'Teacher7'),      -- Course12
(N'Tiếng Anh', N'Tiếng Anh 12 luyện đề', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khóa luyện đề tiếng Anh 12 chuẩn cấu trúc đề thi quốc gia.', 800000, 150, 'Teacher8'),  -- Course13
(N'Sinh học', N'Sinh học 12 di truyền nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Chuyên đề di truyền và biến dị dành cho học sinh khá giỏi.', 600000, 150, 'Teacher8'),  -- Course14
(N'Ngữ văn', N'Ngữ văn 10 cảm thụ văn học', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Phân tích, cảm nhận tác phẩm văn học lớp 10 theo hướng sáng tạo.', 450000, 140, 'Teacher9'),       -- Course15
(N'Lịch sử', N'Lịch sử Việt Nam hiện đại', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tổng quan lịch sử Việt Nam thế kỷ XX và XXI.', 550000, 150, 'Teacher9'),        -- Course16
(N'Tin học', N'Tin học 12 ứng dụng văn phòng', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Sử dụng Word, Excel, PowerPoint hiệu quả trong học tập và thi cử.', 500000, 150, 'Teacher10'), -- Course17
(N'Công nghệ', N'Công nghệ 12 - Lâm nghiệp, thuỷ sản', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Giới thiệu chung về lâm nghiệp; Trồng và chăm sóc rừng; Bảo vệ và khai thác tài nguyên rừng bền vững; Giới thiệu chung về thuỷ sản; Môi trường nuôi thuỷ sản; Công nghệ giống thuỷ sản; Công nghệ thức ăn thuỷ sản; Công nghệ nuôi thuỷ sản; Phòng, trị bệnh thuỷ sản; Bảo vệ và khai thác nguồn lợi thuỷ sản.', 400000, 150, 'Teacher6'), -- Course18
(N'Toán', N'Toán 11 đại số', N'https://res.cloudinary.com/druj32kwu/image/upload/v1748266690/To%C3%A1n_jtqchi.png', N'Hệ phương trình, bất phương trình, logarit và mũ cho lớp 11.', 600000, 150, 'Teacher2'), -- Course19
(N'Hóa học', N'Hóa học 10 cơ bản', N'https://res.cloudinary.com/druj32kwu/image/upload/v1748265930/Chemistry_vswrf7.png', N'Cấu tạo nguyên tử, bảng tuần hoàn và liên kết hóa học.', 550000, 150, 'Teacher4'),       -- Course20
(N'Tiếng Anh', N'Tiếng Anh giao tiếp THPT', N'https://res.cloudinary.com/druj32kwu/image/upload/v1748266328/TiengAnh_cuoidu.png', N'Luyện phản xạ và từ vựng tiếng Anh cho học sinh THPT.', 750000, 150, 'Teacher7'),    -- Course21
(N'Sinh học', N'Sinh học 11 chuyên đề tế bào', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Chuyên đề về cấu trúc và chức năng tế bào nâng cao.', 500000, 150, 'Teacher6'),        -- Course22
(N'Ngữ văn', N'Ngữ văn 11 cảm thụ văn học', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Kỹ năng đọc hiểu và phân tích tác phẩm văn học lớp 11.', 480000, 150, 'Teacher3'),      -- Course23
(N'Lịch sử', N'Lịch sử Việt Nam hiện đại lớp 11', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tìm hiểu cách mạng, chiến tranh và xây dựng đất nước.', 420000, 150, 'Teacher1'),   -- Course24
(N'Địa lý', N'Địa lý kinh tế xã hội lớp 10', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khái niệm và mối quan hệ giữa các yếu tố địa lý kinh tế.', 450000, 150, 'Teacher5'),         -- Course25
(N'Công nghệ', N'Công nghệ 11 - Vẽ kỹ thuật', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Kỹ thuật vẽ hình chiếu, hình cắt và biểu diễn vật thể.', 500000, 150, 'Teacher8'),      -- Course26
(N'Giáo dục công dân', N'GDCD 11 - Quyền công dân', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tìm hiểu pháp luật và trách nhiệm của công dân trong xã hội.', 400000, 150, 'Teacher9'),  -- Course27
(N'Tin học', N'Tin học 12 - Lập trình C++ cơ bản', N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Cấu trúc điều khiển, hàm và mảng trong ngôn ngữ lập trình C++.', 650000, 150, 'Teacher10'); -- Course28


-- INSERT YEUCAUKHOAHOC
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course10', 1, N'Không có'),
('Course1', 1, N'Không có'),
('Course2', 1, N'Đã hoàn thành khóa học Hóa học 10 cơ bản'),
('Course2', 2, N'Nắm vững bảng tuần hoàn và phản ứng hóa học cơ bản'),
('Course3', 1, N'Có khả năng giải bài tập vật lý cơ bản'),
('Course4', 1, N'Không có'),
('Course5', 1, N'Biết sử dụng bản đồ và đọc số liệu địa lý'),
('Course6', 1, N'Không có'),
('Course7', 1, N'Biết sử dụng máy tính và có kiến thức Tin học cơ bản'),
('Course7', 2, N'Đã làm quen với thuật toán và tư duy logic'),
('Course8', 1, N'Đã học xong khóa Tiếng Anh cơ bản hoặc tương đương'),
('Course8', 2, N'Có từ vựng và ngữ pháp trình độ A2 trở lên'),
('Course9', 1, N'Đã học qua kiến thức GDCD lớp 11'),
('Course11', 1, N'Đã hoàn thành khóa học Hóa học 11 nâng cao'),
('Course11', 2, N'Biết cách giải các bài toán phản ứng nâng cao'),
('Course12', 1, N'Không có'),
('Course13', 1, N'Đã hoàn thành Tiếng Anh 10 và 11 nâng cao'),
('Course13', 2, N'Nắm vững ngữ pháp cơ bản và từ vựng học thuật'),
('Course14', 1, N'Hoàn thành Sinh học 10 cơ bản'),
('Course14', 2, N'Đã học kiến thức nền về tế bào và ADN'),
('Course15', 1, N'Không có'),
('Course16', 1, N'Không có'),
('Course17', 1, N'Đã học Tin học 11 lập trình Pascal'),
('Course17', 2, N'Có kỹ năng cơ bản sử dụng máy tính'),
('Course18', 1, N'Không có'),
('Course19', 1, N'Không có');


-- INSERT HOCSINH (Sử dụng TRIGGER để tự động sinh MaHocSinh và GioHang)
-- Dữ liệu này sẽ tự động sinh Student1, Student2, Student3 và tạo Cart_StudentX tương ứng
INSERT INTO HocSinh (MaHocSinh, HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai)
VALUES ('Student1', N'Trần Lâm Nghĩa', 'AQAAAAIAAYagAAAAEDcREY4W4mW7mJGN9DbzaVmBbvdazuKXQXVjTwBTf0fBsGXQcvU3MrOrFJKtCM+p+Q==', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg' ,'tranlamnghia@gmail.com', '0353213325');

-- Chèn Học sinh thứ 2 (dùng TRIGGER sinh ID mới)
INSERT INTO HocSinh (HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai)
VALUES (N'Nguyễn Thị Thu', 'AQAAAAIAAYagAAAAEDcREY4W4mW7mJGN9DbzaVmBbvdazuKXQXVjTwBTf0fBsGXQcvU3MrOrFJKtCM+p+Q==', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'sdgsdfa@gmail.com', '1353213325'); -- Student2

-- Chèn Học sinh thứ 3 (dùng TRIGGER sinh ID mới)
INSERT INTO HocSinh (HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai)
VALUES (N'Phạm Văn Trung', 'AQAAAAIAAYagAAAAEDcREY4W4mW7mJGN9DbzaVmBbvdazuKXQXVjTwBTf0fBsGXQcvU3MrOrFJKtCM+p+Q==', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'pvtrung@example.com', '0345678901'); -- Student3

-- Cập nhật DuongDanAnhDaiDien cho Student3
UPDATE HocSinh SET DuongDanAnhDaiDien = 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg' WHERE MaHocSinh = 'Student3';


-- INSERT KHOAHOC_HOCSINH
INSERT INTO KhoaHoc_HocSinh (MaKhoaHoc, MaHocSinh, NgayDangKy) VALUES
('Course10', 'Student1', NOW()),
('Course13', 'Student1', NOW()),
('Course28', 'Student1', NOW()), -- Course21 trong bản gốc có thể là lỗi chính tả/nhầm lẫn, tôi dùng Course28 (Tin học 12 C++)
('Course21', 'Student1', NOW()), -- Tiếng Anh giao tiếp THPT

('Course9', 'Student2', NOW()),
('Course5', 'Student2', NOW()),
('Course11', 'Student2', NOW());


-- INSERT MUCTIEUKHOAHOC
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course10', 1, N'Củng cố kiến thức hình học không gian lớp 11 nâng cao'),
('Course10', 2, N'Phân tích và giải các bài toán về đường thẳng và mặt phẳng trong không gian'),
('Course10', 3, N'Rèn luyện kỹ năng vẽ hình và tưởng tượng không gian tốt hơn'),
('Course10', 4, N'Vận dụng định lý và công thức hình học vào giải bài tập nâng cao'),
('Course10', 5, N'Chuẩn bị cho các kỳ thi học sinh giỏi và kỳ thi THPT quốc gia phần hình học'),

('Course1', 1, N'Nắm vững các kiến thức cơ bản Toán lớp 10'),
('Course1', 2, N'Rèn luyện kỹ năng giải bài tập cơ bản'),
('Course2', 1, N'Hiểu sâu kiến thức nâng cao về Hóa học lớp 11'),
('Course2', 2, N'Giải quyết các bài tập khó và luyện thi chuyên'),
('Course3', 1, N'Rèn luyện kỹ năng giải bài tập vật lý theo sách giáo khoa'),
('Course3', 2, N'Củng cố kiến thức cơ bản qua thực hành'),
('Course4', 1, N'Tổng hợp kiến thức Ngữ văn 12 ôn thi THPT'),
('Course4', 2, N'Phát triển kỹ năng viết và cảm thụ văn học'),
('Course5', 1, N'Làm quen với cấu trúc đề thi môn Địa lý'),
('Course5', 2, N'Tăng khả năng làm bài thi trắc nghiệm'),
('Course6', 1, N'Tìm hiểu cấu trúc tế bào và di truyền cơ bản'),
('Course6', 2, N'Hình thành nền tảng Sinh học lớp 10'),
('Course7', 1, N'Làm quen cú pháp và lệnh cơ bản trong Pascal'),
('Course7', 2, N'Thực hành viết chương trình đơn giản'),
('Course8', 1, N'Phát triển khả năng nói và giao tiếp tiếng Anh'),
('Course8', 2, N'Nâng cao kỹ năng viết và đọc hiểu'),
('Course9', 1, N'Hiểu rõ quyền và nghĩa vụ công dân trong xã hội'),
('Course9', 2, N'Sẵn sàng cho kỳ thi THPT môn GDCD'),

('Course11', 1, N'Nắm vững các chuyên đề Hóa học lớp 12'),
('Course11', 2, N'Biết cách áp dụng lý thuyết vào bài tập trắc nghiệm'),
('Course11', 3, N'Luyện kỹ năng giải nhanh để thi THPT Quốc gia'),
('Course11', 4, N'Tăng cường phản xạ khi gặp câu hỏi lạ'),
('Course12', 1, N'Hệ thống lại toàn bộ lý thuyết Vật lý lớp 12'),
('Course12', 2, N'Hiểu rõ bản chất các hiện tượng vật lý'),
('Course12', 3, N'Ứng dụng lý thuyết vào giải bài tập nâng cao'),
('Course12', 4, N'Tự tin ôn luyện cho kỳ thi THPT quốc gia'),
('Course13', 1, N'Làm quen với các dạng đề thi THPT Quốc gia'),
('Course13', 2, N'Tăng cường từ vựng và cấu trúc câu học thuật'),
('Course13', 3, N'Nâng cao khả năng đọc hiểu và ngữ pháp'),
('Course13', 4, N'Luyện kỹ năng xử lý câu hỏi nhanh và chính xác'),
('Course14', 1, N'Hiểu sâu về quy luật di truyền học và biến dị'),
('Course14', 2, N'Ứng dụng lý thuyết vào giải bài tập phức tạp'),
('Course14', 3, N'Tăng cường tư duy phân tích và hệ thống kiến thức'),
('Course14', 4, N'Chuẩn bị tốt cho kỳ thi học kỳ và thi đại học'),
('Course15', 1, N'Phát triển kỹ năng đọc hiểu văn bản văn học'),
('Course15', 2, N'Biết cách cảm thụ và phân tích tác phẩm'),
('Course15', 3, N'Tăng khả năng diễn đạt cảm xúc qua bài viết'),
('Course15', 4, N'Chuẩn bị tốt cho các bài kiểm tra đọc hiểu'),
('Course16', 1, N'Hiểu rõ các sự kiện lịch sử Việt Nam thế kỷ XX'),
('Course16', 2, N'Liên hệ lịch sử với thực tiễn hiện nay'),
('Course16', 3, N'Biết cách phân tích, tổng hợp nội dung lịch sử'),
('Course16', 4, N'Làm quen với các dạng câu hỏi trong đề thi sử'),
('Course17', 1, N'Sử dụng thành thạo Word, Excel, PowerPoint'),
('Course17', 2, N'Thực hành tạo báo cáo, bảng biểu chuyên nghiệp'),
('Course17', 3, N'Nắm vững mẹo và kỹ thuật tin học văn phòng'),
('Course17', 4, N'Ứng dụng trong học tập và công việc hành chính'),
('Course18', 1, N'Tìm hiểu về kỹ thuật nuôi trồng thủy sản, lâm nghiệp'),
('Course18', 2, N'Tiếp cận các mô hình công nghệ trong sản xuất nông nghiệp'),
('Course18', 3, N'Hiểu rõ chuỗi sản xuất và bảo quản sản phẩm nông lâm nghiệp'),
('Course18', 4, N'Ứng dụng kiến thức vào thực tiễn đời sống và nghề nghiệp'),
('Course19', 1, N'Nắm vững các chuyên đề đại số lớp 11'),
('Course19', 2, N'Luyện kỹ năng giải phương trình và bất phương trình'),
('Course19', 3, N'Phát triển tư duy logic và khả năng suy luận'),
('Course19', 4, N'Chuẩn bị nền tảng vững chắc cho chương trình lớp 12');


-- INSERT BAIHOC (Sử dụng TRIGGER để tự động sinh MaBaiHoc)
INSERT INTO BaiHoc (MaKhoaHoc, ThuTu, TieuDe, LinkVideo) VALUES
-- Course10
('Course10', 1, N'Định hướng học hình học không gian nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course10', 2, N'Phân tích bài toán đường thẳng và mặt phẳng', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course10', 3, N'Kỹ thuật vẽ hình và tưởng tượng không gian', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course1
('Course1', 1, N'Giới thiệu Toán 10 và định hướng học tập', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course1', 2, N'Phương pháp giải phương trình bậc hai', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course1', 3, N'Thực hành các dạng toán cơ bản', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course2
('Course2', 1, N'Cấu tạo nguyên tử nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course2', 2, N'Phân tích phản ứng oxi hóa khử', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course2', 3, N'Bài tập tổng hợp chương 1-3', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course3
('Course3', 1, N'Cơ bản về chuyển động cơ', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course3', 2, N'Phân tích đồ thị chuyển động', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course3', 3, N'Giải bài tập sách giáo khoa phần I', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course4
('Course4', 1, N'Chiến lược ôn tập Ngữ văn 12', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course4', 2, N'Phân tích tác phẩm trọng tâm', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course4', 3, N'Luyện kỹ năng viết đoạn văn nghị luận', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course5
('Course5', 1, N'Ôn tập Địa lý tự nhiên Việt Nam', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course5', 2, N'Kỹ năng đọc và phân tích bản đồ', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course5', 3, N'Thực hành giải đề thi thử', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course6
('Course6', 1, N'Cấu trúc tế bào', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course6', 2, N'Sinh học phân tử cơ bản', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course6', 3, N'Gen, ADN và di truyền học sơ lược', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course7
('Course7', 1, N'Giới thiệu ngôn ngữ Pascal', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course7', 2, N'Biến, kiểu dữ liệu và nhập xuất', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course7', 3, N'Cấu trúc điều kiện và lặp', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course8
('Course8', 1, N'Luyện phát âm tiếng Anh chuẩn', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course8', 2, N'Cấu trúc ngữ pháp nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course8', 3, N'Giao tiếp thực tế theo chủ đề', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course9
('Course9', 1, N'Công dân với pháp luật', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course9', 2, N'Quyền và nghĩa vụ cơ bản', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course9', 3, N'Bài tập tình huống và tư duy pháp lý', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course11
('Course11', 1, N'Giới thiệu chuyên đề Hóa 12', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course11', 2, N'Phản ứng oxi hóa khử', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course11', 3, N'Hướng dẫn luyện đề trắc nghiệm', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course12
('Course12', 1, N'Lý thuyết dao động cơ', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course12', 2, N'Dòng điện xoay chiều', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course12', 3, N'Sóng điện từ', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course13
('Course13', 1, N'Chiến thuật làm bài đọc hiểu', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course13', 2, N'Luyện đề ngữ pháp nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course13', 3, N'Cách chọn đáp án nhanh', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course14
('Course14', 1, N'Cơ sở di truyền học', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course14', 2, N'Bài tập phả hệ', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course14', 3, N'Tổng hợp lý thuyết di truyền nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course15
('Course15', 1, N'Phân tích thơ hiện đại', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course15', 2, N'Cảm thụ tác phẩm tự sự', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course15', 3, N'Tổng hợp các phương pháp đọc hiểu', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course16
('Course16', 1, N'Khái quát Việt Nam thế kỷ XX', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course16', 2, N'Các cuộc kháng chiến chống Pháp và Mỹ', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course16', 3, N'Việt Nam thời kỳ đổi mới', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course17
('Course17', 1, N'Word căn bản và nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course17', 2, N'Excel trong thống kê dữ liệu', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course17', 3, N'PowerPoint trình bày chuyên nghiệp', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course18
('Course18', 1, N'Nguyên lý kỹ thuật nuôi trồng', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course18', 2, N'Ứng dụng công nghệ sinh học', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course18', 3, N'Phát triển bền vững trong sản xuất', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4'),

-- Course19
('Course19', 1, N'Hàm số và đồ thị lớp 11', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course19', 2, N'Dãy số và quy nạp toán học', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course19', 3, N'Phép biến hình và ứng dụng', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4');


-- INSERT CHITIETGIOHANG
INSERT INTO ChiTietGioHang (MaGioHang, MaKhoaHoc, NgayThem) VALUES
('Cart_Student2', 'Course4', NOW()),
('Cart_Student2', 'Course6', NOW()),
('Cart_Student2', 'Course7', NOW()),
('Cart_Student2', 'Course13', NOW()),
('Cart_Student2', 'Course14', NOW()),
('Cart_Student2', 'Course15', NOW()),
('Cart_Student2', 'Course16', NOW());


-- INSERT ADMIN
INSERT INTO Admin (MaAdmin, HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai)
VALUES (
    'Admin001',
    N'Admin',
    'AQAAAAIAAYagAAAAEPBTMAOrkabgrzzyPWbupIoCW+A3XEkgDYhkECpIKh+I4MXb/bfXzmvY1cqAtjDA6Q==',
    'https://res.cloudinary.com/your_cloud_name/image/upload/default_admin_avatar.png',
    'admin_chinh@example.com',
    '0123456789'
);

-- --------------------------------------------------------
-- SELECT STATEMENTS (dùng để kiểm tra dữ liệu sau khi INSERT)
-- --------------------------------------------------------

-- Select GiaoVien
SELECT * FROM GiaoVien ORDER BY CAST(SUBSTR(MaGiaoVien, 8) AS UNSIGNED) ASC;

-- Select KhoaHoc
SELECT * FROM KhoaHoc ORDER BY CAST(SUBSTR(MaKhoaHoc, 7) AS UNSIGNED) ASC;

-- Select HocSinh
SELECT * FROM HocSinh;

-- Select KhoaHoc_HocSinh
SELECT * FROM KhoaHoc_HocSinh;

-- Select MucTieuKhoaHoc
SELECT * FROM MucTieuKhoaHoc;

-- Select YeuCauKhoaHoc
SELECT * FROM YeuCauKhoaHoc;

-- Select GioHang
SELECT * FROM GioHang;

-- Select ChiTietGioHang
SELECT * FROM ChiTietGioHang;

-- Select Admin
SELECT * FROM Admin;