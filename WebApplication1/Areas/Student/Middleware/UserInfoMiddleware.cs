using System.Security.Claims;
using WebApplication1.Models;

namespace WebApplication1.Areas.Student.Middleware
{
    public class UserInfoMiddleware
    {
        private readonly RequestDelegate _next;

        public UserInfoMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, AppDbContext dbContext)
        {
            if (context.User.Identity.IsAuthenticated)
            {
                var maHocSinh = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var role = context.User.FindFirst(ClaimTypes.Role)?.Value;

                if (!string.IsNullOrEmpty(maHocSinh) && role == "Student")
                {
                    var hocSinh = dbContext.HocSinhs.FirstOrDefault(h => h.MaHocSinh == maHocSinh);
                    if (hocSinh != null)
                    {
                        var userInfo = new
                        {
                            UserName = hocSinh.HoTen ?? hocSinh.DienThoai,
                            Email = hocSinh.Email ?? "Không có email",
                            AvatarUrl = hocSinh.DuongDanAnhDaiDien ?? "/images/default-avatar.png",
                            Role = "Student"
                        };
                        context.Items["UserInfo"] = userInfo;
                    }
                }
            }

            await _next(context);
        }
    }

    public static class UserInfoMiddlewareExtensions
    {
        public static IApplicationBuilder UseUserInfo(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<UserInfoMiddleware>();
        }
    }
}
