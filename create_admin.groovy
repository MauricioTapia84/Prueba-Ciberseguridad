#!groovy
import jenkins.model.*
import hudson.security.*
def instance = Jenkins.getInstance()
def hudsonRealm = instance.getSecurityRealm()
if (hudsonRealm == null) {
  def realm = new HudsonPrivateSecurityRealm(false)
  instance.setSecurityRealm(realm)
}
def userId = "admin_reset"
def password = "Cambiar123!"
def fullName = "Admin Reset"
def email = "admin@example.local"
def user = instance.getSecurityRealm().createAccount(userId, password)
user.setFullName(fullName)
def pm = instance.getInjector().getInstance(hudson.tasks.Mailer.DescriptorImpl.class)
user.save()
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()
println("Created user ${userId} with password ${password}")
