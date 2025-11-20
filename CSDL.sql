CREATE DATABASE QUANLYKHOAHOC;
GO

USE QUANLYKHOAHOC;
GO

CREATE TABLE dbo.GiaoVien (
    MaGiaoVien			NVARCHAR(20)	NOT NULL PRIMARY KEY,  -- TeacherXXX
    HoTen               NVARCHAR(200)   NOT NULL,
    DuongDanAnhDaiDien  NVARCHAR(1000)  NULL,
    Email               NVARCHAR(200)   NOT NULL UNIQUE,
    DienThoai           NVARCHAR(50)    NULL,
    GioiThieu           NVARCHAR(MAX)   NULL,
    NgayTao             DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.KhoaHoc (
    MaKhoaHoc			NVARCHAR(20)    NOT NULL PRIMARY KEY,  -- CourseXXX
    MonHoc              NVARCHAR(100)   NOT NULL,
    TieuDe              NVARCHAR(300)   NOT NULL,
    DuongDanAnhKhoaHoc  NVARCHAR(1000)  NULL,
    MoTa                NVARCHAR(MAX)   NOT NULL,
	GiaKhoaHoc			DECIMAL(10,2)	NOT NULL,
    ThoiHan				INT				NOT NULL DEFAULT 150,  -- đơn vị: ngày
    MaGiaoVien			NVARCHAR(20)    NOT NULL,            -- FK → GiaoVien
    NgayCapNhat         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_KhoaHoc_GiaoVien
      FOREIGN KEY(MaGiaoVien) REFERENCES dbo.GiaoVien(MaGiaoVien)
      ON UPDATE CASCADE ON DELETE NO ACTION
);
GO


CREATE TABLE dbo.MucTieuKhoaHoc (
    MaKhoaHoc			NVARCHAR(20)	NOT NULL,
    ThuTu				INT				NOT NULL,                         -- Mục tiêu số 1, 2, 3 trong khóa học
    NoiDung				NVARCHAR(1000)	NOT NULL,
    PRIMARY KEY (MaKhoaHoc, ThuTu),             -- Khóa chính kết hợp
    FOREIGN KEY (MaKhoaHoc) REFERENCES dbo.KhoaHoc(MaKhoaHoc)
        ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE dbo.YeuCauKhoaHoc (
    MaKhoaHoc			NVARCHAR(20)	NOT NULL,
    ThuTu				INT				NOT NULL,
    NoiDung				NVARCHAR(1000)	NOT NULL,
    PRIMARY KEY (MaKhoaHoc, ThuTu),
    FOREIGN KEY (MaKhoaHoc) REFERENCES dbo.KhoaHoc(MaKhoaHoc)
        ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE dbo.BaiHoc (
    MaBaiHoc			NVARCHAR(30)    NOT NULL PRIMARY KEY,  -- CourseXXX_YY
    MaKhoaHoc			NVARCHAR(20)    NOT NULL,            -- FK → KhoaHoc
    ThuTu               INT             NOT NULL,
    TieuDe              NVARCHAR(200)   NULL,
    LinkVideo           NVARCHAR(1000)  NOT NULL,
    NgayTao             DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_BaiHoc_KhoaHoc
      FOREIGN KEY(MaKhoaHoc) REFERENCES dbo.KhoaHoc(MaKhoaHoc)
      ON UPDATE CASCADE ON DELETE CASCADE
);
GO

CREATE TABLE dbo.HocSinh (
    MaHocSinh      NVARCHAR(20)   NOT NULL PRIMARY KEY,  -- StudentXXX
    HoTen          NVARCHAR(200)  NOT NULL,
	PassHash       VARCHAR(MAX)	  NOT NULL,
	DuongDanAnhDaiDien  NVARCHAR(1000)  NULL,
    Email          NVARCHAR(200)  NOT NULL UNIQUE,
    DienThoai      NVARCHAR(50)   NULL,
    NgaySinh       DATE           NULL,
    GioiTinh       NVARCHAR(10)   NULL,
    DiaChi         NVARCHAR(500)  NULL,
    NgayDangKy     DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.GioHang (
    MaGioHang   NVARCHAR(30)     NOT NULL PRIMARY KEY,         -- VD: Cart_Student001
    MaHocSinh   NVARCHAR(20)     NOT NULL,              -- Mỗi học sinh chỉ có 1 giỏ hàng
    NgayTao     DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_GioHang_HocSinh
		FOREIGN KEY (MaHocSinh) REFERENCES dbo.HocSinh(MaHocSinh)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO

CREATE TABLE dbo.ChiTietGioHang (
    MaGioHang   NVARCHAR(30)     NOT NULL,
    MaKhoaHoc   NVARCHAR(20)     NOT NULL,
    NgayThem    DATETIME        NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (MaGioHang, MaKhoaHoc),
    FOREIGN KEY (MaGioHang) REFERENCES dbo.GioHang(MaGioHang)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MaKhoaHoc) REFERENCES dbo.KhoaHoc(MaKhoaHoc)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO


CREATE TABLE dbo.KhoaHoc_HocSinh (
    MaKhoaHoc     NVARCHAR(20)  NOT NULL,  -- FK
    MaHocSinh     NVARCHAR(20)  NOT NULL,  -- FK
    NgayDangKy    DATETIME      NOT NULL DEFAULT GETDATE()
    PRIMARY KEY (MaKhoaHoc, MaHocSinh),
    CONSTRAINT FK_KhoaHocHocSinh_KhoaHoc
        FOREIGN KEY (MaKhoaHoc) REFERENCES dbo.KhoaHoc(MaKhoaHoc)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_KhoaHocHocSinh_HocSinh
        FOREIGN KEY (MaHocSinh) REFERENCES dbo.HocSinh(MaHocSinh)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO


CREATE TRIGGER trg_GiaoVien_InsteadOfInsert
ON dbo.GiaoVien
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm lưu các mã đang có
    DECLARE @Used TABLE (ID INT);
    INSERT INTO @Used (ID)
    SELECT CAST(SUBSTRING(MaGiaoVien, 8, LEN(MaGiaoVien) - 7) AS INT)
    FROM dbo.GiaoVien
    WHERE ISNUMERIC(SUBSTRING(MaGiaoVien, 8, LEN(MaGiaoVien) - 7)) = 1;

    DECLARE @MinUnused INT = 1;

    WHILE EXISTS (
        SELECT 1 FROM @Used WHERE ID = @MinUnused
    )
    BEGIN
        SET @MinUnused += 1;
    END

    INSERT INTO dbo.GiaoVien
        (MaGiaoVien, HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu, NgayTao)
    SELECT
        COALESCE(i.MaGiaoVien, 'Teacher' + CAST(@MinUnused AS VARCHAR)),
        i.HoTen, i.DuongDanAnhDaiDien, i.Email, i.DienThoai, i.GioiThieu,
        GETDATE()
    FROM inserted AS i;
END;
GO

CREATE TRIGGER trg_HocSinh_InsteadOfInsert
ON dbo.HocSinh
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaxID INT;

    -- Lấy số thứ tự lớn nhất hiện tại
    SELECT @MaxID = MAX(CAST(SUBSTRING(MaHocSinh, 8, LEN(MaHocSinh) - 7) AS INT))
    FROM dbo.HocSinh
    WHERE ISNUMERIC(SUBSTRING(MaHocSinh, 8, LEN(MaHocSinh) - 7)) = 1;

    SET @MaxID = ISNULL(@MaxID, 0);

    -- Table variable để chứa học sinh mới và dùng lại
    DECLARE @NewStudents TABLE (
        MaHocSinh NVARCHAR(20),
        HoTen NVARCHAR(200),
        PassHash VARCHAR(MAX),
        DuongDanAnhDaiDien NVARCHAR(1000),
        Email NVARCHAR(200),
        DienThoai NVARCHAR(50),
        NgaySinh DATE,
        GioiTinh NVARCHAR(10),
        DiaChi NVARCHAR(500)
    );

    -- Tạo danh sách học sinh mới và chèn vào bảng tạm
    INSERT INTO @NewStudents (MaHocSinh, HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai, NgaySinh, GioiTinh, DiaChi)
    SELECT
        'Student' + CAST(@MaxID + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR),
        HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai, NgaySinh, GioiTinh, DiaChi
    FROM inserted;

    -- Thêm vào bảng HocSinh
    INSERT INTO dbo.HocSinh (MaHocSinh, HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai, NgaySinh, GioiTinh, DiaChi, NgayDangKy)
    SELECT
        MaHocSinh, HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai, NgaySinh, GioiTinh, DiaChi, GETDATE()
    FROM @NewStudents;

    -- Tạo giỏ hàng tương ứng
    INSERT INTO dbo.GioHang (MaGioHang, MaHocSinh, NgayTao)
    SELECT
        'Cart_' + MaHocSinh,
        MaHocSinh,
        GETDATE()
    FROM @NewStudents;
END;
GO



-- 6. Trigger INSTEAD OF INSERT cho KhoaHoc
CREATE TRIGGER trg_KhoaHoc_InsteadOfInsert
ON dbo.KhoaHoc
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @baseMax INT = (
      SELECT ISNULL(MAX(CAST(SUBSTRING(MaKhoaHoc,7,3) AS INT)),0)
      FROM dbo.KhoaHoc
    );

    INSERT INTO dbo.KhoaHoc
      (MaKhoaHoc, MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien, NgayCapNhat)
    SELECT
      COALESCE(i.MaKhoaHoc,
        'Course' + RIGHT(CAST(@baseMax + ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS VARCHAR(3)),3)
      ),
      i.MonHoc, i.TieuDe, i.DuongDanAnhKhoaHoc, i.MoTa, i.GiaKhoaHoc, i.ThoiHan, i.MaGiaoVien, GETDATE()
    FROM inserted AS i;

END;
GO

-- 7. Trigger INSTEAD OF INSERT cho BaiHoc
CREATE TRIGGER dbo.trg_BaiHoc_InsteadOfInsert
ON dbo.BaiHoc
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Thêm bài học mới
    INSERT INTO dbo.BaiHoc
        (MaBaiHoc, MaKhoaHoc, ThuTu, TieuDe, LinkVideo, NgayTao)
    SELECT
        COALESCE(i.MaBaiHoc,
            i.MaKhoaHoc + '_' + RIGHT('00' + CAST(i.ThuTu AS VARCHAR(2)), 2)
        ),
        i.MaKhoaHoc, i.ThuTu, i.TieuDe, i.LinkVideo, GETDATE()
    FROM inserted AS i;

END;


----- INSERT GIAOVIEN
INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Nguyễn Văn A', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'nguyenvana748@example.com', '0901234567', N'Hơn 10 năm kinh nghiệm trong nghề');

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Trần Thị B', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'tranthib982@example.com', '0912345678', N'Giáo viên nhiệt tình trẻ tuổi');

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Lê Văn C', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'levanc351@example.com', '0923456789', N'Giáo viên nhiệt tình trẻ tuổi');

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Phạm Thị D', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'phamthid623@example.com', '0934567890', N'Giáo viên nhiệt tình trẻ tuổi');

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Hoàng Văn E', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'hoangvane107@example.com', '0945678901', NULL);

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Vũ Thị F', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'vuthif462@example.com', '0956789012', NULL);

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Đặng Văn G', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'dangvang715@example.com', '0967890123', NULL);

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Bùi Thị H', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'buithih289@example.com', '0978901234', NULL);

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Ngô Văn I', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg', 'ngovani390@example.com', '0989012345', NULL);

INSERT INTO GiaoVien (HoTen, DuongDanAnhDaiDien, Email, DienThoai, GioiThieu)
VALUES (N'Đỗ Thị K', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/2_s0bzbb.jpg', 'dothik178@example.com', '0990123456', NULL);


----- INSERT KHOAHOC
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Toán', N'Toán 10 cơ bản', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khóa học toán lớp 10 cơ bản dành cho học sinh phổ thông.', 500000, DEFAULT, 'Teacher1');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Hóa học', N'Hóa học 11 nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Nâng cao kiến thức hóa học lớp 11 với các chuyên đề nâng cao.', 650000, 140, 'Teacher1');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Vật lý', N'Vật lý 10 - Sách bài tập', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Hướng dẫn giải bài tập Vật lý 10 theo chương trình chuẩn.', 400000, DEFAULT, 'Teacher2');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Ngữ văn', N'Ngữ văn 12 ôn thi THPT', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tổng hợp kiến thức ngữ văn lớp 12 để ôn thi THPT.', 700000, 140, 'Teacher3');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Địa lý', N'Địa lý 12 luyện đề', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Luyện tập các đề thi thử địa lý lớp 12 theo cấu trúc đề thi mới.', 550000, 140, 'Teacher4');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Sinh học', N'Sinh học 10 cơ bản', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tìm hiểu cấu trúc tế bào, sinh học phân tử và di truyền học cơ bản.', 500000, DEFAULT, 'Teacher4');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Tin học', N'Tin học 11 lập trình Pascal', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khóa học lập trình Pascal cơ bản dành cho học sinh lớp 11.', 600000, DEFAULT, 'Teacher5');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Tiếng Anh', N'Tiếng Anh 10 nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Trọn bộ kiến thức nâng cao tiếng Anh lớp 10, phát âm và giao tiếp.', 750000, DEFAULT, 'Teacher5');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Giáo dục công dân', N'GDCD 12 trọng tâm', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tổng hợp kiến thức GDCD 12 trọng tâm thi THPT.', 400000, 140, 'Teacher6');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Toán', N'Toán 11 hình học nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Chuyên đề hình học không gian lớp 11 nâng cao.', 600000, DEFAULT, 'Teacher6');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Hóa học', N'Hóa học 12 luyện thi đại học', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Các chuyên đề trọng điểm hóa học 12, luyện thi THPT quốc gia.', 700000, DEFAULT, 'Teacher7');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Vật lý', N'Vật lý 12 lý thuyết trọng tâm', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Các phần lý thuyết quan trọng Vật lý lớp 12, ôn luyện thi.', 500000, 140, 'Teacher7');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Tiếng Anh', N'Tiếng Anh 12 luyện đề', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Khóa luyện đề tiếng Anh 12 chuẩn cấu trúc đề thi quốc gia.', 800000, DEFAULT, 'Teacher8');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Sinh học', N'Sinh học 12 di truyền nâng cao', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Chuyên đề di truyền và biến dị dành cho học sinh khá giỏi.', 600000, DEFAULT, 'Teacher8');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Ngữ văn', N'Ngữ văn 10 cảm thụ văn học', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Phân tích, cảm nhận tác phẩm văn học lớp 10 theo hướng sáng tạo.', 450000, 140, 'Teacher9');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Lịch sử', N'Lịch sử Việt Nam hiện đại', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Tổng quan lịch sử Việt Nam thế kỷ XX và XXI.', 550000, DEFAULT, 'Teacher9');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Tin học', N'Tin học 12 ứng dụng văn phòng', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Sử dụng Word, Excel, PowerPoint hiệu quả trong học tập và thi cử.', 500000, DEFAULT, 'Teacher10');

INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Công nghệ', N'Công nghệ 12 - Lâm nghiệp, thuỷ sản', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png', N'Giới thiệu chung về lâm nghiệp; Trồng và chăm sóc rừng; Bảo vệ và khai thác tài nguyên rừng bền vững; Giới thiệu chung về thuỷ sản; Môi trường nuôi thuỷ sản; Công nghệ giống thuỷ sản; Công nghệ thức ăn thuỷ sản; Công nghệ nuôi thuỷ sản; Phòng, trị bệnh thuỷ sản; Bảo vệ và khai thác nguồn lợi thuỷ sản.', 400000, DEFAULT, 'Teacher6');

---------Bổ sung dữ liệu khóa học
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Toán', N'Toán 11 đại số', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1748266690/To%C3%A1n_jtqchi.png',
N'Hệ phương trình, bất phương trình, logarit và mũ cho lớp 11.', 600000, DEFAULT, 'Teacher2');

-- 2. Hóa học - Lớp 10 cơ bản
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Hóa học', N'Hóa học 10 cơ bản', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1748265930/Chemistry_vswrf7.png',
N'Cấu tạo nguyên tử, bảng tuần hoàn và liên kết hóa học.', 550000, DEFAULT, 'Teacher4');

-- 3. Tiếng Anh - Giao tiếp THPT
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Tiếng Anh', N'Tiếng Anh giao tiếp THPT', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1748266328/TiengAnh_cuoidu.png',
N'Luyện phản xạ và từ vựng tiếng Anh cho học sinh THPT.', 750000, DEFAULT, 'Teacher7');

-- 4. Sinh học - Lớp 11 tế bào nâng cao
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Sinh học', N'Sinh học 11 chuyên đề tế bào', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Chuyên đề về cấu trúc và chức năng tế bào nâng cao.', 500000, DEFAULT, 'Teacher6');

-- 5. Ngữ văn - Cảm thụ tác phẩm văn học 11
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Ngữ văn', N'Ngữ văn 11 cảm thụ văn học', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Kỹ năng đọc hiểu và phân tích tác phẩm văn học lớp 11.', 480000, DEFAULT, 'Teacher3');

-- 6. Lịch sử - Việt Nam hiện đại lớp 11
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Lịch sử', N'Lịch sử Việt Nam hiện đại lớp 11', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Tìm hiểu cách mạng, chiến tranh và xây dựng đất nước.', 420000, DEFAULT, 'Teacher1');

-- 7. Địa lý - Địa lý kinh tế xã hội lớp 10
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Địa lý', N'Địa lý kinh tế xã hội lớp 10', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Khái niệm và mối quan hệ giữa các yếu tố địa lý kinh tế.', 450000, DEFAULT, 'Teacher5');

-- 8. Công nghệ - Vẽ kỹ thuật lớp 11
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Công nghệ', N'Công nghệ 11 - Vẽ kỹ thuật', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Kỹ thuật vẽ hình chiếu, hình cắt và biểu diễn vật thể.', 500000, DEFAULT, 'Teacher8');

-- 9. Giáo dục công dân - Quyền và nghĩa vụ công dân
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Giáo dục công dân', N'GDCD 11 - Quyền công dân', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Tìm hiểu pháp luật và trách nhiệm của công dân trong xã hội.', 400000, DEFAULT, 'Teacher9');

-- 10. Tin học - Lập trình C++ lớp 12
INSERT INTO KhoaHoc (MonHoc, TieuDe, DuongDanAnhKhoaHoc, MoTa, GiaKhoaHoc, ThoiHan, MaGiaoVien)
VALUES (N'Tin học', N'Tin học 12 - Lập trình C++ cơ bản', 
N'https://res.cloudinary.com/druj32kwu/image/upload/v1747841841/unknown_g8spau.png',
N'Cấu trúc điều khiển, hàm và mảng trong ngôn ngữ lập trình C++.', 650000, DEFAULT, 'Teacher10');

INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES ('Course10', 1, N'Không có');

insert into HocSinh (MaHocSinh, HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai) 
values ('Student1', N'Trần Lâm Nghĩa', 'AQAAAAIAAYagAAAAEDcREY4W4mW7mJGN9DbzaVmBbvdazuKXQXVjTwBTf0fBsGXQcvU3MrOrFJKtCM+p+Q==', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg' ,'tranlamnghia@gmail.com', '0353213325');

INSERT INTO KhoaHoc_HocSinh (MaKhoaHoc, MaHocSinh, NgayDangKy) VALUES ('Course10', 'Student1', GETDATE());
INSERT INTO KhoaHoc_HocSinh (MaKhoaHoc, MaHocSinh, NgayDangKy) VALUES ('Course13', 'Student1', GETDATE());
INSERT INTO KhoaHoc_HocSinh (MaKhoaHoc, MaHocSinh, NgayDangKy) VALUES ('Course20', 'Student1', GETDATE());
INSERT INTO KhoaHoc_HocSinh (MaKhoaHoc, MaHocSinh, NgayDangKy) VALUES ('Course21', 'Student1', GETDATE());

INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, NoiDung, ThuTu) VALUES
('Course10', N'Củng cố kiến thức hình học không gian lớp 11 nâng cao', 1),
('Course10', N'Phân tích và giải các bài toán về đường thẳng và mặt phẳng trong không gian', 2),
('Course10', N'Rèn luyện kỹ năng vẽ hình và tưởng tượng không gian tốt hơn', 3),
('Course10', N'Vận dụng định lý và công thức hình học vào giải bài tập nâng cao', 4),
('Course10', N'Chuẩn bị cho các kỳ thi học sinh giỏi và kỳ thi THPT quốc gia phần hình học', 5);

INSERT INTO BaiHoc (MaKhoaHoc, ThuTu, TieuDe, LinkVideo)
VALUES 
('Course10', 1, N'Định hướng học hình học không gian nâng cao', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-29_hm5ri6.mp4'),
('Course10', 2, N'Phân tích bài toán đường thẳng và mặt phẳng', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358829/2025-05-27_22-12-36_monkyj.mp4'),
('Course10', 3, N'Kỹ thuật vẽ hình và tưởng tượng không gian', 'https://res.cloudinary.com/druj32kwu/video/upload/v1748358830/2025-05-27_22-12-42_eufxva.mp4');
---------INSERT FULL
-- Course1
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course1', 1, N'Không có');

-- Course2
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course2', 1, N'Đã hoàn thành khóa học Hóa học 10 cơ bản'),
('Course2', 2, N'Nắm vững bảng tuần hoàn và phản ứng hóa học cơ bản');

-- Course3
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course3', 1, N'Có khả năng giải bài tập vật lý cơ bản');

-- Course4
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course4', 1, N'Không có');

-- Course5
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course5', 1, N'Biết sử dụng bản đồ và đọc số liệu địa lý');

-- Course6
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course6', 1, N'Không có');

-- Course7
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course7', 1, N'Biết sử dụng máy tính và có kiến thức Tin học cơ bản'),
('Course7', 2, N'Đã làm quen với thuật toán và tư duy logic');

-- Course8
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course8', 1, N'Đã học xong khóa Tiếng Anh cơ bản hoặc tương đương'),
('Course8', 2, N'Có từ vựng và ngữ pháp trình độ A2 trở lên');

-- Course9
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
('Course9', 1, N'Đã học qua kiến thức GDCD lớp 11');

-- Course11 - Hóa học 12 luyện thi đại học
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course11', 1, N'Đã hoàn thành khóa học Hóa học 11 nâng cao'),
('Course11', 2, N'Biết cách giải các bài toán phản ứng nâng cao');

-- Course12 - Vật lý 12 lý thuyết trọng tâm
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course12', 1, N'Không có');

-- Course13 - Tiếng Anh 12 luyện đề
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course13', 1, N'Đã hoàn thành Tiếng Anh 10 và 11 nâng cao'),
('Course13', 2, N'Nắm vững ngữ pháp cơ bản và từ vựng học thuật');

-- Course14 - Sinh học 12 di truyền nâng cao
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course14', 1, N'Hoàn thành Sinh học 10 cơ bản'),
('Course14', 2, N'Đã học kiến thức nền về tế bào và ADN');

-- Course15 - Ngữ văn 10 cảm thụ văn học
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course15', 1, N'Không có');

-- Course16 - Lịch sử Việt Nam hiện đại
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course16', 1, N'Không có');

-- Course17 - Tin học 12 ứng dụng văn phòng
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course17', 1, N'Đã học Tin học 11 lập trình Pascal'),
('Course17', 2, N'Có kỹ năng cơ bản sử dụng máy tính');

-- Course18 - Công nghệ 12 - Lâm nghiệp, thủy sản
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course18', 1, N'Không có');

-- Course19 - Toán 11 đại số
INSERT INTO YeuCauKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course19', 1, N'Không có');



INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES 
-- Course1
('Course1', 1, N'Nắm vững các kiến thức cơ bản Toán lớp 10'),
('Course1', 2, N'Rèn luyện kỹ năng giải bài tập cơ bản'),

-- Course2
('Course2', 1, N'Hiểu sâu kiến thức nâng cao về Hóa học lớp 11'),
('Course2', 2, N'Giải quyết các bài tập khó và luyện thi chuyên'),

-- Course3
('Course3', 1, N'Rèn luyện kỹ năng giải bài tập vật lý theo sách giáo khoa'),
('Course3', 2, N'Củng cố kiến thức cơ bản qua thực hành'),

-- Course4
('Course4', 1, N'Tổng hợp kiến thức Ngữ văn 12 ôn thi THPT'),
('Course4', 2, N'Phát triển kỹ năng viết và cảm thụ văn học'),

-- Course5
('Course5', 1, N'Làm quen với cấu trúc đề thi môn Địa lý'),
('Course5', 2, N'Tăng khả năng làm bài thi trắc nghiệm'),

-- Course6
('Course6', 1, N'Tìm hiểu cấu trúc tế bào và di truyền cơ bản'),
('Course6', 2, N'Hình thành nền tảng Sinh học lớp 10'),

-- Course7
('Course7', 1, N'Làm quen cú pháp và lệnh cơ bản trong Pascal'),
('Course7', 2, N'Thực hành viết chương trình đơn giản'),

-- Course8
('Course8', 1, N'Phát triển khả năng nói và giao tiếp tiếng Anh'),
('Course8', 2, N'Nâng cao kỹ năng viết và đọc hiểu'),

-- Course9
('Course9', 1, N'Hiểu rõ quyền và nghĩa vụ công dân trong xã hội'),
('Course9', 2, N'Sẵn sàng cho kỳ thi THPT môn GDCD');

-- Course11 - Hóa học 12 luyện thi đại học
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course11', 1, N'Nắm vững các chuyên đề Hóa học lớp 12'),
('Course11', 2, N'Biết cách áp dụng lý thuyết vào bài tập trắc nghiệm'),
('Course11', 3, N'Luyện kỹ năng giải nhanh để thi THPT Quốc gia'),
('Course11', 4, N'Tăng cường phản xạ khi gặp câu hỏi lạ');

-- Course12 - Vật lý 12 lý thuyết trọng tâm
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course12', 1, N'Hệ thống lại toàn bộ lý thuyết Vật lý lớp 12'),
('Course12', 2, N'Hiểu rõ bản chất các hiện tượng vật lý'),
('Course12', 3, N'Ứng dụng lý thuyết vào giải bài tập nâng cao'),
('Course12', 4, N'Tự tin ôn luyện cho kỳ thi THPT quốc gia');

-- Course13 - Tiếng Anh 12 luyện đề
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course13', 1, N'Làm quen với các dạng đề thi THPT Quốc gia'),
('Course13', 2, N'Tăng cường từ vựng và cấu trúc câu học thuật'),
('Course13', 3, N'Nâng cao khả năng đọc hiểu và ngữ pháp'),
('Course13', 4, N'Luyện kỹ năng xử lý câu hỏi nhanh và chính xác');

-- Course14 - Sinh học 12 di truyền nâng cao
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course14', 1, N'Hiểu sâu về quy luật di truyền học và biến dị'),
('Course14', 2, N'Ứng dụng lý thuyết vào giải bài tập phức tạp'),
('Course14', 3, N'Tăng cường tư duy phân tích và hệ thống kiến thức'),
('Course14', 4, N'Chuẩn bị tốt cho kỳ thi học kỳ và thi đại học');

-- Course15 - Ngữ văn 10 cảm thụ văn học
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course15', 1, N'Phát triển kỹ năng đọc hiểu văn bản văn học'),
('Course15', 2, N'Biết cách cảm thụ và phân tích tác phẩm'),
('Course15', 3, N'Tăng khả năng diễn đạt cảm xúc qua bài viết'),
('Course15', 4, N'Chuẩn bị tốt cho các bài kiểm tra đọc hiểu');

-- Course16 - Lịch sử Việt Nam hiện đại
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course16', 1, N'Hiểu rõ các sự kiện lịch sử Việt Nam thế kỷ XX'),
('Course16', 2, N'Liên hệ lịch sử với thực tiễn hiện nay'),
('Course16', 3, N'Biết cách phân tích, tổng hợp nội dung lịch sử'),
('Course16', 4, N'Làm quen với các dạng câu hỏi trong đề thi sử');

-- Course17 - Tin học 12 ứng dụng văn phòng
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course17', 1, N'Sử dụng thành thạo Word, Excel, PowerPoint'),
('Course17', 2, N'Thực hành tạo báo cáo, bảng biểu chuyên nghiệp'),
('Course17', 3, N'Nắm vững mẹo và kỹ thuật tin học văn phòng'),
('Course17', 4, N'Ứng dụng trong học tập và công việc hành chính');

-- Course18 - Công nghệ 12 - Lâm nghiệp, thuỷ sản
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course18', 1, N'Tìm hiểu về kỹ thuật nuôi trồng thủy sản, lâm nghiệp'),
('Course18', 2, N'Tiếp cận các mô hình công nghệ trong sản xuất nông nghiệp'),
('Course18', 3, N'Hiểu rõ chuỗi sản xuất và bảo quản sản phẩm nông lâm nghiệp'),
('Course18', 4, N'Ứng dụng kiến thức vào thực tiễn đời sống và nghề nghiệp');

-- Course19 - Toán 11 đại số
INSERT INTO MucTieuKhoaHoc (MaKhoaHoc, ThuTu, NoiDung) VALUES
('Course19', 1, N'Nắm vững các chuyên đề đại số lớp 11'),
('Course19', 2, N'Luyện kỹ năng giải phương trình và bất phương trình'),
('Course19', 3, N'Phát triển tư duy logic và khả năng suy luận'),
('Course19', 4, N'Chuẩn bị nền tảng vững chắc cho chương trình lớp 12');


-- Course1
INSERT INTO BaiHoc (MaKhoaHoc, ThuTu, TieuDe, LinkVideo) VALUES
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



INSERT INTO KhoaHoc_HocSinh(MaKhoaHoc, MaHocSinh) VALUES ('Course9', 'Student2')
INSERT INTO KhoaHoc_HocSinh(MaKhoaHoc, MaHocSinh) VALUES ('Course5', 'Student2')
INSERT INTO KhoaHoc_HocSinh(MaKhoaHoc, MaHocSinh) VALUES ('Course11', 'Student2')

CREATE TABLE Admin(
	MaAdmin				NVARCHAR(20)   NOT NULL PRIMARY KEY,  -- StudentXXX
    HoTen				NVARCHAR(200)  NOT NULL,
	PassHash			VARCHAR(MAX)	  NOT NULL,
	DuongDanAnhDaiDien  NVARCHAR(1000)  NULL,
    Email				NVARCHAR(200)  NOT NULL UNIQUE,
    DienThoai			NVARCHAR(50)   NULL
)
GO


SELECT *
FROM dbo.GiaoVien
ORDER BY CAST(SUBSTRING(MaGiaoVien, 8, LEN(MaGiaoVien) - 7) AS INT) ASC;

SELECT * FROM KhoaHoc
ORDER BY CAST(SUBSTRING(MaKhoaHoc, 7, LEN(MaKhoaHoc) - 6) AS INT) ASC;

select * from HocSinh
select * from KhoaHoc_HocSinh
select * from MucTieuKhoaHoc
select * from YeuCauKhoaHoc


update HocSinh set DuongDanAnhDaiDien = 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg' where MaHocSinh = 'Student3'


INSERT INTO Admin (
    MaAdmin, 
    HoTen, 
    PassHash, 
    DuongDanAnhDaiDien, 
    Email, 
    DienThoai
)
VALUES (
    'Admin001',                                                        -- MaAdmin: ID duy nhất cho admin
    N'Admin',                                         -- HoTen: Tên của admin
    'AQAAAAIAAYagAAAAEPBTMAOrkabgrzzyPWbupIoCW+A3XEkgDYhkECpIKh+I4MXb/bfXzmvY1cqAtjDA6Q==', -- PassHash: Mật khẩu ĐÃ ĐƯỢC HASH AN TOÀN cho admin này
    'https://res.cloudinary.com/your_cloud_name/image/upload/default_admin_avatar.png', -- DuongDanAnhDaiDien: URL ảnh đại diện (hoặc NULL nếu cho phép)
    'admin_chinh@example.com',                                         -- Email: Email của admin
    '0123456789'                                                    -- DienThoai: Số điện thoại (hoặc NULL)

);
-- sodienthoai: 0123456789 matkhau: 12345

insert into HocSinh (HoTen, PassHash, DuongDanAnhDaiDien, Email, DienThoai) 
values (N'Trần Lâm Nghĩa', 'AQAAAAIAAYagAAAAEDcREY4W4mW7mJGN9DbzaVmBbvdazuKXQXVjTwBTf0fBsGXQcvU3MrOrFJKtCM+p+Q==', 'https://res.cloudinary.com/druj32kwu/image/upload/v1747840647/1_manaaf.jpg' ,'sdgsdfa@gmail.com', '1353213325');

select * from GioHang
select * from KhoaHoc_HocSinh where MaHocSinh = 'Student2'
select * from ChiTietGioHang
SELECT * FROM KhoaHoc
ORDER BY CAST(SUBSTRING(MaKhoaHoc, 7, LEN(MaKhoaHoc) - 6) AS INT) ASC;




insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course4')
insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course6')
insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course7')
insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course13')
insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course14')
insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course15')
insert into ChiTietGioHang (MaGioHang, MaKhoaHoc) VALUES ('Cart_Student2', 'Course16')
