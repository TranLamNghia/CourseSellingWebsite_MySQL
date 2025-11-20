using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class Admin
{
    public string MaAdmin { get; set; } = null!;

    public string HoTen { get; set; } = null!;

    public string PassHash { get; set; } = null!;

    public string? DuongDanAnhDaiDien { get; set; }

    public string Email { get; set; } = null!;

    public string? DienThoai { get; set; }
}
