using CloudinaryDotNet;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using WebApplication1.Areas.Student.Middleware;
using WebApplication1.Areas.Student.Services;
using WebApplication1.Models;
using WebApplication1.Services;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();
// Add services to the container.
builder.Services.AddDbContext<AppDbContext>(options => options.UseMySql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        ServerVersion.AutoDetect(builder.Configuration.GetConnectionString("DefaultConnection"))
    )
);
builder.Services.Configure<CloudinarySettings>(builder.Configuration.GetSection("CloudinarySettings"));
builder.Services.AddSingleton<Cloudinary>(provider =>
{
    var settings = provider.GetRequiredService<IOptions<CloudinarySettings>>().Value;
    return new Cloudinary(new Account(settings.CloudName, settings.ApiKey, settings.ApiSecret));
});
builder.Services.AddScoped<CloudinaryService>();

// Thêm và cấu hình Authentication với Cookie
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/signin"; // Trang đăng nhập khi chưa xác thực
        options.LogoutPath = "/signout"; // Trang đăng xuất
        options.AccessDeniedPath = "/access-denied"; // Trang khi không có quyền truy cập
        options.ExpireTimeSpan = TimeSpan.FromMinutes(30); // Thời gian hết hạn của cookie
    });

builder.Services.AddLogging(logging =>
{
    logging.AddConsole();
    logging.AddDebug();
    logging.SetMinimumLevel(LogLevel.Debug);
});

builder.Services.AddScoped<ICartStudent, ItemCartStudentService>();
builder.Services.AddScoped<IVNPayService, VNPayService>();

// Thêm Authorization
builder.Services.AddAuthorization();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// Thêm middleware cho Authentication và Authorization (ĐÂY LÀ THỨ TỰ ĐÚNG)
app.UseAuthentication();
app.UseAuthorization();

// Middleware tùy chỉnh
app.UseUserInfo();

// Đảm bảo route cho Areas (nếu có)
app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=HomePage}/{id?}");

app.Run();