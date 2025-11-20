using Microsoft.AspNetCore.Mvc;
using WebApplication1.Models.VNPay;
using WebApplication1.Services;

namespace WebApplication1.Controllers
{
    public class PaymentController : Controller
    {
        private readonly IVNPayService _vnPayService;
        public PaymentController(IVNPayService vnPayService)
        {

            _vnPayService = vnPayService;
        }

        public IActionResult CreatePaymentUrlVnpay(PaymentInformationModel model)
        {
            var url = _vnPayService.CreatePaymentUrl(model, HttpContext);

            return Redirect(url);
        }
        

    }
}
