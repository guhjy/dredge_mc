
############### Model selection using a customized dredge function to account for multicollinearity #################
library(MuMIn)
library(nlme)
library(lme4)
library(MASS)

## Dataset with correlated variables
data(airquality)
airquality <- airquality[complete.cases(airquality), ]
airquality$Month <- factor(airquality$Month)
str(airquality)
cor(airquality[ , 1:4])

### Full models containing continuous predictor variables
lm.model <- lm(Temp ~ Ozone + Solar.R + Wind, data=airquality)
glm.model <- glm(Day ~ Ozone + Solar.R + Wind, data=airquality, family = "poisson")
glm.nb.model <- glm.nb(Day ~ Ozone + Solar.R + Wind, data=airquality)
gls.model <- gls(Temp ~ Ozone + Solar.R + Wind, data=airquality, method="ML")
lme.model <- lme(Temp ~ Ozone + Solar.R + Wind, random = ~1| Month, data=airquality, method="ML")
lmer.model <- lmer(Temp ~ Ozone + Solar.R + Wind + (1|Month), data=airquality, REML=F)
glmer.model <- glmer(Day ~ scale(Ozone) + scale(Solar.R) + scale(Wind) + (1|Month), data=airquality, family="poisson")

### Function to calculate maximum correlation coefficient between predictor variables, retrieved from each model
max.r <- function(x){
  if(class(x)[length(class(x))] == "lm"){
    corm <- summary(x, correlation=TRUE)$correlation}
  else if(class(x) =="lmerMod"){
    corm <- cov2cor(vcov(x))}
  else if(class(x) =="glmerMod"){
    corm <- cov2cor(vcov(x))}
  else if(class(x)=="gls"){
    corm <- summary(x)$corBeta} 
  else if(class(x)=="lme"){
    corm <- summary(x)$corFixed}
  else { print("Error: Invalid model class")}
  corm <- as.matrix(corm)
  if (length(corm)==1){
    corm <- 0
    max(abs(corm))
  } else if (length(corm)==4){
    cormf <- corm[2:nrow(corm),2:ncol(corm)]
    cormf <- 0
    max(abs(cormf))
  } else {
    cormf <- corm[2:nrow(corm),2:ncol(corm)]
    diag(cormf) <- 0
    max(abs(cormf))
  }
}

max.r(lm.model) ## Test function
max.r(glm.model) ## Test function
max.r(glm.nb.model) ## Test function
max.r(gls.model) ## Test function
max.r(lme.model) ## Test function
max.r(lmer.model) ## Test function
max.r(glmer.model) ## Test function

### Model selection accounting for multicollinearity
options(na.action = na.fail)
model <- lm.model ## Define model to be used
Allmodels <- dredge(model, rank = "AIC", m.lim=c(0, 3), extra= c(max.r)) ###Run dredge specifying the number of predictor variables and including the max.r function
NCM <- get.models(Allmodels, subset = max.r<=0.6) ##Retrieve non-collinear models (max.r <=0.6)
model.sel(NCM) ##Final model selection table

