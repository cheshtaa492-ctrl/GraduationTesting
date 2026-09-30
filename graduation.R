data <- data.frame(age=c(20:60))

data
data$etr <- 1000*0.95^(data$age-20)
data

a <- 0.01
b <- 0.0005
c <- 1.09


data$true_mortality <- a+b*c^data$age
set.seed(1650)
data$deaths <- rbinom(n = nrow(data), size = round(data$etr), prob = data$true_mortality)


data$crude_mortality <- data$deaths/data$etr

data

plot(data$age,data$true_mortality,type ="l",col="red",ylim = c(0,0.1))
lines(data$age,data$crude_mortality,col ="blue")

# we can see the crude mortality rates are definately not smooth

# Smoothing the crude mortality rates
# using parametric approach for smoothening
# weighted least squares 
fit_weighted <- nls(data$crude_mortality~a+b*c^data$age, data = data,
                    start = list(a = 0.002, b = 0.0003, c = 1.08),
                    weights = data$etr)
summ <- summary(fit_weighted)

a <- summ$coefficients[1]
b <- summ$coefficients[2]
c <- summ$coefficients[3]
data$weighted <- a+b*c^data$age 


# 2nd graduatation using splines function

library(splines)
fit_spline <- smooth.spline(data$age,data$crude_mortality,w = data$etr)

data$graduated_splines <- predict(fit_spline,data$age)$y


lines(data$age,data$graduated_splines,col ="green")
lines(data$age,data$weighted,col ="purple")




legend("topleft",legend = c("true mortality rates","crude Mortality rates","weighted ","splines"),col =c("red","blue","green","purple"),lwd = 0.4)


#runing the chi square test for weighted graudted rates
data$zx <- ((data$deaths-data$etr*data$weighted)/(data$etr*data$weighted))

data$zx_squared <- ((data$deaths - data$etr*data$weighted)^2) / (data$etr*data$weighted)
chi_sq_stat <- sum(data$zx_squared)
data

crit <- qchisq(0.95, df = 38)
yn <- ifelse(chi_sq_stat < crit, 1, 0)

ifelse(yn == 1, "Graduation works good", "Graduation doesn't work good")




#testing for splines graudted rates

data$spline_zx <- ((data$deaths-data$etr*data$graduated_splines)/(data$etr*data$graduated_splines))

data$zx_spline_squared <- data$spline_zx^2
chi_sq_stat_spline <- sum(data$zx_spline_squared)
data

crit_spline <- qchisq(0.95, df = 38)
yn_spline <- ifelse(chi_sq_stat_spline < crit_spline, 1, 0)

ifelse(yn_spline == 1, "Graduation works good", "Graduation doesn't work good")


data

# signs test for weighted graduated rates'

# count signs
pos <- sum(data$zx > 0)
neg <- sum(data$zx < 0)

# binomial test
binom.test(pos, pos+neg, p=0.5)


# 
# signs test for splines graduated rates

# count signs
pos_sp <- sum(data$spline_zx > 0)
neg_sp <- sum(data$spline_zx < 0)

# binomial test
binom.test(pos_sp, pos_sp+neg_sp, p=0.5)


#Cumulative Deviation tests for weighted 
# crude vs graduated rates
crude <- data$deaths / data$etr
grad  <- data$weighted

# deviations
dev <- crude - grad

# cumulative deviations
cum_dev <- cumsum(dev)

# plot cumulative deviations
plot(cum_dev, type="l", main="Cumulative Deviations", 
     ylab="Cumulative deviation", xlab="Age")

# test statistic = max absolute cumulative deviation
test_stat <- max(abs(cum_dev))
test_stat




# Cumulative Deviation tests for Splines
# crude vs graduated rates
crude_spline <- data$deaths / data$etr
grad_spline  <- data$graduated_splines

# deviations
dev_spline <- crude_spline - grad_spline

# cumulative deviations
cum_dev_spline <- cumsum(dev_spline)

# plot cumulative deviations
lines(data$age,cum_dev_spline, type="l", col ="red")


# test statistic = max absolute cumulative deviation
test_stat <- max(abs(cum_dev_spline))
test_stat



