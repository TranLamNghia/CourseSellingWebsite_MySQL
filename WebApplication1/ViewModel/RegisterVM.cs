using System.ComponentModel.DataAnnotations;

namespace WebApplication1.ViewModels
{
    public class RegisterVM
    {
        [Required(ErrorMessage = "Họ là bắt buộc.")]
        public string LastName { get; set; }

        [Required(ErrorMessage = "Tên là bắt buộc.")]
        public string FirstName { get; set; }

        public string HoTen => $"{LastName} {FirstName}";
        [Required]
        [Phone]
        public string DienThoai { get; set; }

        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; }
        [Required(ErrorMessage = "Xác nhận mật khẩu là bắt buộc.")]
        [DataType(DataType.Password)]
        [Compare("Password", ErrorMessage = "Mật khẩu xác nhận không khớp.")]
        public string ConfirmPassword { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public string UserType { get; set; } // Student hoặc Admin
    }
}