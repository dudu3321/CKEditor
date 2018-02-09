using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(TestCKEditor.Startup))]
namespace TestCKEditor
{
    public partial class Startup {
        public void Configuration(IAppBuilder app) {
            ConfigureAuth(app);
        }
    }
}
