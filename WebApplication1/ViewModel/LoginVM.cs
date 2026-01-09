using System.ComponentModel.DataAnnotations;

namespace WebApplication1.ViewModel
{
    public class LoginVM
    {
        [Required]
        [Phone]
        public string DienThoai { get; set; }
        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; }
        public bool RememberMe { get; set; }
        public string UserType { get; set; }
    }
}