#R commands and output:

##  Import ascii data file.
y <- scan("../res/zarr14.dat",skip=25)

#Generate histogram.
hist(y)
##  Attach mclust library.
#install.packages("mclust")
library(mclust)

##  Fit bimodal mixture model.
yBIC = mclustBIC(y, modelNames="V")
yModel = mclustModel(y, yBIC)

##  Print model parameters.
yModel$parameters$mean

#>        1        2
#> 9.182039 9.261662 

yModel$parameters$variance$sigmasq

#> [1] 0.0004006869 0.0005188599
#R commands and output:

## Read data.
m <- matrix(scan("../res/jahanmi2.dat",skip=50),ncol=16,byrow=T)
y = m[,5]
x1 = m[,6]
x2 = m[,7]
x3 = m[,8]
x4 = m[,9]
lab = m[,2]
batch = m[,14]

## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations   480.00000
#> Mean                     650.07731
#> Std. Dev.                 74.63826
#> Std. Dev. of Mean          3.40675
#> Variance                5570.86967
#> Range                    476.36000
#> Lower Hinge              595.97400
#> Upper Hinge              708.42200
#> Inter-Quartile Range     112.29000
#> Autocorrelation           -0.22905

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   345.3   596.1   646.6   650.1   708.3   821.7 


## Generate a 4-plot of the data.
library(Hmisc)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(y,ylab="Y",xlab="Run Sequence")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Strength of Ceramic Material: 4-Plot", line = 0.5, outer = TRUE)


## Generate bihistogram.
library(Hmisc)
histbackback(split(y,batch),ylab="Strength of Ceramic",
             brks=seq(300,900,by=25))


## Generate a quantile-quantile plot for the two batches.
df = data.frame(y,batch)
y1 = df[batch==1,1]
y2 = df[batch==2,1]
qqplot(y2,y1)
abline(0,1)
title(sub="Quantile-Quantile Plot Y1 Y2")

## Generate box plots for each batch.
boxplot(y~batch,ylab="Ceramic Strength",xlab="Batch")
title("Box Plot by Batch")


## Generate block plots for each factor.
## Save variables as factors.
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
flab = factor(lab)
fbatch = factor(batch)
df = data.frame(y,fbatch,flab,fx1,fx2,fx3)

## Generate four plots on one page.
par(mfrow=c(2,2))

## Compute the batch means for each laboratory.
avg = aggregate(x=df$y, by=list(df$flab,df$fbatch), FUN="mean")

## Generate the block plot.
boxplot(avg$x ~ avg$Group.1, medlty="blank",
        ylab="Ceramic Strength",xlab="Laboratory",
        main="Batch Means for Each Laboratory")
## Add labels for the batch means.
text(avg$Group.1[avg$Group.2==1], avg$x[avg$Group.2==1],
     labels=avg$Group.2[avg$Group.2==1], pos=1)
text(avg$Group.1[avg$Group.2==2], avg$x[avg$Group.2==2],
     labels=avg$Group.2[avg$Group.2==2], pos=3)

## Generate the block plot for the first factor.
## Create new variable that indicates batch*x1.
## The new variable is necessary to preserve the order
## of the blocks within laboratory.
newx1 = x1/5
lx1 = factor(lab + newx1)
df = data.frame(y,fbatch,lx1)
## Compute the batch means for each laboratory and level of x1.
avg = aggregate(x=df$y, by=list(df$fbatch,df$lx1), FUN="mean")
## Specify locations of the bars on the x axis.
xpos = c(1,5,8,10,13:14,16:17,19:20,22:23)
boxplot(avg$x ~ avg$Group.2, medlty="blank", xlim=c(1,24),
        ylab="Ceramic Strength",xlab="Laboratory and x1",
        at=xpos,xaxt="n",main="Batch Means:  Lab and x1")
axis(side=1,at=c(1.5,4.5,7.5,10.5,13.5,16.5,19.5,22.5),
     labels=c("1","2","3","4","5","6","7","8"))
## Add labels for the batch means.
text(xpos,avg$x[avg$Group.1==1],
     labels=avg$Group.1[avg$Group.1==1], pos=1)
text(xpos,avg$x[avg$Group.1==2],
     labels=avg$Group.1[avg$Group.1==2], pos=3)

## Generate the block plot for the second factor.
## Create new variable that indicates batch*x2.
newx2 = x2/5
lx2 = factor(lab + newx2)
df = data.frame(y,fbatch,lx2)
## Compute the batch means for each laboratory and level of x2.
avg = aggregate(x=df$y, by=list(df$fbatch,df$lx2), FUN="mean")
## Specify locations of the bars on the x axis.
xpos = c(1:2,4:5,7:8,10:11,13,17,20,22)
boxplot(avg$x ~ avg$Group.2, medlty="blank", xlim=c(1,24),
        ylab="Ceramic Strength",xlab="Laboratory and x2",
        at=xpos ,xaxt="n",main="Batch Means:  Lab and x2")
axis(side=1,at=c(1.5,4.5,7.5,10.5,13.5,16.5,19.5,22.5),
     labels=c("1","2","3","4","5","6","7","8"))
## Add labels for the batch means.
text(xpos, avg$x[avg$Group.1==1],
     labels=avg$Group.1[avg$Group.1==1], pos=1)
text(xpos, avg$x[avg$Group.1==2],
     labels=avg$Group.1[avg$Group.1==2], pos=3)

## Generate the block plot for the third factor.
## Create new variable that indicates batch*x3.
newx3 = x3/5
lx3 = factor(lab + newx3)
df = data.frame(y,fbatch,lx3)
## Compute the batch means for each laboratory and level of x3.
avg = aggregate(x=df$y, by=list(df$fbatch,df$lx3), FUN="mean")
## Specify locations of the bars on the x axis.
xpos = c(1:2,4:5,7:8,10:11,13:14,16:17,19:20,22:23)
boxplot(avg$x ~ avg$Group.2, medlty="blank", xlim=c(1,24),
        ylab="Ceramic Strength",xlab="Laboratory and x3",
        at=xpos ,xaxt="n",main="Batch Means:  Lab and x3")
axis(side=1,at=c(1.5,4.5,7.5,10.5,13.5,16.5,19.5,22.5),
     labels=c("1","2","3","4","5","6","7","8"))
## Add labels for the batch means.
text(xpos, avg$x[avg$Group.1==1],
     labels=avg$Group.1[avg$Group.1==1], pos=1)
text(xpos, avg$x[avg$Group.1==2],
     labels=avg$Group.1[avg$Group.1==2], pos=3)


## Perform an F-test to compare two variances.
var.test(y~batch)

#>         F test to compare two variances
#>
#> data:  y by batch 
#> F = 1.123, num df = 239, denom df = 239, p-value = 0.3704
#> alternative hypothesis: true ratio of variances is not equal to 1 
#> 95 percent confidence interval:
#>  0.8709874 1.4480271 
#> sample estimates:
#> ratio of variances 
#>          1.123038 


## Perform a two-sample T-test for the case where group variances
## are equal.
t.test(y~batch,var.equal=TRUE,alternative="greater")

#>         Two Sample t-test
#>
#> data:  y by batch 
#> t = 13.3806, df = 478, p-value < 2.2e-16
#> alternative hypothesis: true difference in means is greater than 0 
#> 95 percent confidence interval:
#>  68.25501      Inf 
#> sample estimates:
#> mean in group 1 mean in group 2 
#>        688.9986        611.1560 

## Compute pooled standard deviation. 
## (When sample sizes are equal, take the average of variances.)
s = aggregate(x=df$y, by=list(df$fbatch), FUN="sd")
sp2 = (s$x[1]^2 + s$x[2]^2)/2
sp = sqrt(sp2)
sp

#> [1] 63.70167


## Generate a box plot for each laboratory.
boxplot(y~lab,ylab="Ceramic Strength",xlab="Laboratory")


## Create a dataframe with batch 1 data and generate the box plot.
df = data.frame(y,lab,batch)
df1 = df[df$batch==1,]
boxplot(y~lab,data=df1,ylab="Ceramic Strength",xlab="Laboratory")
title("Batch Number 1")


## Create a dataframe with batch 2 data and generate the box plot.
df2 = df[df$batch==2,]
boxplot(y~lab,data=df2,ylab="Ceramic Strength",xlab="Laboratory")
title("Batch Number 2")


## Generate DEX scatter plot for batch 1.
## Restructure data so that x1, x2, and x3 are in a single column.
## Also, save re-coded version of the factor levels for DEX mean plot.
tempx  = x1
tempxc = x1 + 1
dm1 = cbind(y,lab,batch,tempx,tempxc)
tempx  = x2
tempxc = x2 + 4
dm2 = cbind(y,lab,batch,tempx,tempxc)
tempx  = x3
tempxc = x3 + 7
dm3 = cbind(y,lab,batch,tempx,tempxc)
dm4 = rbind(dm1,dm2,dm3)

## Generate factor ID variable.
n = length(y)
varind = c(rep("Table Speed",n),rep("Feed Rate",n),rep("Wheel Grit Size",n))
varind = as.factor(varind)

## Create a dataframe with "stacked" factors and data.
df = data.frame(dm4,varind)

## Create a dataframe for batch 1 data.
df1 = df[df$batch==1,]

## Attach lattice library and generate the DEX scatter plot.
library(lattice)
xyplot(y~tempx|varind,data=df1,layout=c(3,1),xlim=c(-2,2),
       ylab="Ceramic Strength",xlab="Factor Levels",
       main="Batch 1")


## Comute grand mean for batch 1.
ybar = mean(m[ m[,14]==1,5])

## Generate DEX mean plot for batch 1.
interaction.plot(df1$tempxc,df1$varind,df1$y,fun=mean,
                 ylab="Ceramic Strength",xlab="",main="Batch 1",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=ybar)


## Comute overall standard deviation for batch 1.
sdy = sd(m[ m[,14]==1,5])

## Generate DEX standard deviation plot.
interaction.plot(df1$tempxc,df1$varind,df1$y,fun=sd,
                 ylab="Ceramic Strength",xlab="",main="Batch 1",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=sdy)


## Create a dataframe with batch 2 data.
df2 = df[df$batch==2,]

## Attach lattice library and generate the DEX scatter plot for batch 2.
library(lattice)
xyplot(y~tempx|varind,data=df2,layout=c(3,1),xlim=c(-2,2),
       ylab="Ceramic Strength",xlab="Factor Levels",
       main="Batch 2")


## Comute grand mean for batch 2.
ybar = mean(m[ m[,14]==2,5])

## Generate DEX mean plot for batch 2.
interaction.plot(df2$tempxc,df2$varind,df2$y,fun=mean,
                 ylab="Ceramic Strength",xlab="",main="Batch 2",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=ybar)


## Comute grand mean for batch 2.
sdy = sd(m[ m[,14]==2,5])

## Generate DEX standard deviation plot for batch 2.
interaction.plot(df2$tempxc,df2$varind,df2$y,fun=sd,
                 ylab="Ceramic Strength",xlab="",main="Batch 2",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=sdy)


## Generate DEX Interaction Plot for Batch 1.

## Create dataframe.
x12 = x1*x2
x13 = x1*x3
x23 = x2*x3
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
fx12 = factor(x12)
fx13 = factor(x13)
fx23 = factor(x23)
dfip = data.frame(y,batch,fx1,fx2,fx3,fx12,fx13,fx23)

## Create a dataframe for batch 1 data.
dfip1 = dfip[dfip$batch==1,]

## Compute overall batch mean.
ybar1 = mean(dfip1$y)

## Compute effect estimates and factor means.
q = aggregate(x=dfip1$y,by=list(dfip1$fx1),FUN="mean")
x1lo = q[1,2]
x1hi = q[2,2]
e1 = x1lo-x1hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx2),FUN="mean")
x2lo = q[1,2]
x2hi = q[2,2]
e2 = x2lo - x2hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx3),FUN="mean")
x3lo = q[1,2]
x3hi = q[2,2]
e3 = x3lo - x3hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx12),FUN="mean")
x12lo = q[1,2]
x12hi = q[2,2]
e12 = x12lo - x12hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx13),FUN="mean")
x13lo = q[1,2]
x13hi = q[2,2]
e13 = x13lo - x13hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx23),FUN="mean")
x23lo = q[1,2]
x23hi = q[2,2]
e23 = x23lo - x23hi

# Create factor labels from effect values.
e = round(c(e3,e2,e23,e1,e12,e13),2)
textlabs = c("X3 Effect =","X2 Effect =","X2*X3 Effect =",
             "X1 Effect =","X1*X2 Effect =","X1*X3 Effect =")
labs = paste(textlabs,e)
group = factor(c(1:6),labels=labs)

# Create data frame with factor level means.
x = c(x3lo,x2lo,x23lo,x1lo,x12lo,x13lo)
xlev = rep(-1,6)
xlo = cbind(x,xlev,group)

x = c(x3hi,x2hi,x23hi,x1hi,x12hi,x13hi)
xlev = rep(1,6)
xhi = cbind(x,xlev,group)

m = rbind(xlo,xhi)
m = as.data.frame(m)

# Customize Lattice plot layout and color.
sp = c(T,T,F,T,F,F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)

# Generate plot.
xyplot(x~xlev | group, data=m, type="b", xlim=c(-2,2),
       layout=c(3,3), skip=sp, col=c(4), 
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=labs,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Strength", main="Batch 1",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = ybar1, lty = 2, col = 2)
}
)


## Generate DEX Interaction Plot for Batch 2.

## Create a dataframe for batch 2 data.
dfip2 = dfip[dfip$batch==2,]

## Compute overall batch mean.
ybar2 = mean(dfip2$y)

## Compute effect estimates and factor means.
q = aggregate(x=dfip2$y,by=list(dfip2$fx1),FUN="mean")
x1lo = q[1,2]
x1hi = q[2,2]
e1 = x1lo-x1hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx2),FUN="mean")
x2lo = q[1,2]
x2hi = q[2,2]
e2 = x2lo - x2hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx3),FUN="mean")
x3lo = q[1,2]
x3hi = q[2,2]
e3 = x3lo - x3hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx12),FUN="mean")
x12lo = q[1,2]
x12hi = q[2,2]
e12 = x12lo - x12hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx13),FUN="mean")
x13lo = q[1,2]
x13hi = q[2,2]
e13 = x13lo - x13hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx23),FUN="mean")
x23lo = q[1,2]
x23hi = q[2,2]
e23 = x23lo - x23hi

# Create factor labels from effect values.
e = round(c(e3,e2,e23,e1,e12,e13),2)
textlabs = c("X3 Effect =","X2 Effect =","X2*X3 Effect =",
             "X1 Effect =","X1*X2 Effect =","X1*X3 Effect =")
labs = paste(textlabs,e)
group = factor(c(1:6),labels=labs)

# Create data frame with factor level means.
x = c(x3lo,x2lo,x23lo,x1lo,x12lo,x13lo)
xlev = rep(-1,6)
xlo = cbind(x,xlev,group)

x = c(x3hi,x2hi,x23hi,x1hi,x12hi,x13hi)
xlev = rep(1,6)
xhi = cbind(x,xlev,group)

m = rbind(xlo,xhi)
m = as.data.frame(m)

# Customize Lattice plot layout and color.
sp = c(T,T,F,T,F,F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)

# Generate plot.
xyplot(x~xlev | group, data=m, type="b", xlim=c(-2,2),
       layout=c(3,3), skip=sp, col=c(4), 
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=labs,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Strength", main="Batch 2",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = ybar2, lty = 2, col = 2)
}
)
#R commands for ceramic strength case study (1.4.2.10):

############################
## Analyses for 1.4.2.10.2 #
############################

## Read data.
fname <- "../res/jahanmi2.dat"
m <- matrix(scan(fname,skip=50),ncol=16,byrow=T)
y = m[,5]
x1 = m[,6]
x2 = m[,7]
x3 = m[,8]
x4 = m[,9]
lab = m[,2]
batch = m[,14]

## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

## Compute the five number summary.
## min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format and print results.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)
summary(y)

## Generate a 4-plot of the data.
library(Hmisc)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(y,ylab="Y",xlab="Run Sequence")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Strength of Ceramic Material: 4-Plot", line = 0.5, outer = TRUE)
par(mfrow=c(1,1))

############################
## Analyses for 1.4.2.10.3 #
############################

## Generate bihistogram.
library(Hmisc)
histbackback(split(y,batch),ylab="Strength of Ceramic",
             brks=seq(300,900,by=25))

## Generate a quantile-quantile plot for the two batches.
df = data.frame(y,batch)
y1 = df[batch==1,1]
y2 = df[batch==2,1]
qqplot(y2,y1)
abline(0,1)
title(sub="Quantile-Quantile Plot Y1 Y2")

## Generate a box plot for each batch.
boxplot(y~batch,ylab="Ceramic Strength",xlab="Batch")
title("Box Plot by Batch")

## Save variables as factors.
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
flab = factor(lab)
fbatch = factor(batch)
df = data.frame(y,fbatch,flab,fx1,fx2,fx3)

## Generate four plots on one page.
par(mfrow=c(2,2))

## Plot #1
## Compute the batch means for each laboratory.
avg = aggregate(x=df$y, by=list(df$flab,df$fbatch), FUN="mean")

## Generate the block plot.
boxplot(avg$x ~ avg$Group.1, medlty="blank",
        ylab="Ceramic Strength",xlab="Laboratory",
        main="Batch Means for Each Laboratory")
## Add labels for the batch means.
text(avg$Group.1[avg$Group.2==1], avg$x[avg$Group.2==1],
     labels=avg$Group.2[avg$Group.2==1], pos=1)
text(avg$Group.1[avg$Group.2==2], avg$x[avg$Group.2==2],
     labels=avg$Group.2[avg$Group.2==2], pos=3)

## Plot #2
## Generate the block plot for the first factor.
## Create new variable that indicates batch*x1.
## The new variable is necessary to preserve the order
## of the blocks within laboratory.
newx1 = x1/5
lx1 = factor(lab + newx1)
df = data.frame(y,fbatch,lx1)

## Compute the batch means for each laboratory and level of x1.
avg = aggregate(x=df$y, by=list(df$fbatch,df$lx1), FUN="mean")
## Specify locations of the bars on the x axis.
xpos = c(1,5,8,10,13:14,16:17,19:20,22:23)
boxplot(avg$x ~ avg$Group.2, medlty="blank", xlim=c(1,24),
        ylab="Ceramic Strength",xlab="Laboratory and x1",
        at=xpos,xaxt="n",main="Batch Means:  Lab and x1")
axis(side=1,at=c(1.5,4.5,7.5,10.5,13.5,16.5,19.5,22.5),
     labels=c("1","2","3","4","5","6","7","8"))
## Add labels for the batch means.
text(xpos,avg$x[avg$Group.1==1],
     labels=avg$Group.1[avg$Group.1==1], pos=1)
text(xpos,avg$x[avg$Group.1==2],
     labels=avg$Group.1[avg$Group.1==2], pos=3)

## Plot #3
## Generate the block plot for the second factor.
## Create new variable that indicates batch*x2.
newx2 = x2/5
lx2 = factor(lab + newx2)
df = data.frame(y,fbatch,lx2)
## Compute the batch means for each laboratory and level of x2.
avg = aggregate(x=df$y, by=list(df$fbatch,df$lx2), FUN="mean")
## Specify locations of the bars on the x axis.
xpos = c(1:2,4:5,7:8,10:11,13,17,20,22)
boxplot(avg$x ~ avg$Group.2, medlty="blank", xlim=c(1,24),
        ylab="Ceramic Strength",xlab="Laboratory and x2",
        at=xpos ,xaxt="n",main="Batch Means:  Lab and x2")
axis(side=1,at=c(1.5,4.5,7.5,10.5,13.5,16.5,19.5,22.5),
     labels=c("1","2","3","4","5","6","7","8"))
## Add labels for the batch means.
text(xpos, avg$x[avg$Group.1==1],
     labels=avg$Group.1[avg$Group.1==1], pos=1)
text(xpos, avg$x[avg$Group.1==2],
     labels=avg$Group.1[avg$Group.1==2], pos=3)

## Plot #4
## Generate the block plot for the third factor.
## Create new variable that indicates batch*x3.
newx3 = x3/5
lx3 = factor(lab + newx3)
df = data.frame(y,fbatch,lx3)
## Compute the batch means for each laboratory and level of x3.
avg = aggregate(x=df$y, by=list(df$fbatch,df$lx3), FUN="mean")
## Specify locations of the bars on the x axis.
xpos = c(1:2,4:5,7:8,10:11,13:14,16:17,19:20,22:23)
boxplot(avg$x ~ avg$Group.2, medlty="blank", xlim=c(1,24),
        ylab="Ceramic Strength",xlab="Laboratory and x3",
        at=xpos ,xaxt="n",main="Batch Means:  Lab and x3")
axis(side=1,at=c(1.5,4.5,7.5,10.5,13.5,16.5,19.5,22.5),
     labels=c("1","2","3","4","5","6","7","8"))
## Add labels for the batch means.
text(xpos, avg$x[avg$Group.1==1],
     labels=avg$Group.1[avg$Group.1==1], pos=1)
text(xpos, avg$x[avg$Group.1==2],
     labels=avg$Group.1[avg$Group.1==2], pos=3)
par(mfrow=c(1,1))

## Perform an F-test to compare two variances.
var.test(y~batch)

## Perform a two-sample T-test for the case where group variances
## are equal.
t.test(y~batch,var.equal=TRUE,alternative="greater")

############################
## Analyses for 1.4.2.10.4 #
############################

## Generate box plot for each laboratory.
boxplot(y~lab,ylab="Ceramic Strength",xlab="Laboratory")

## Create a dataframe with batch 1 data and generate the box plot.
df = data.frame(y,lab,batch)
df1 = df[df$batch==1,]
boxplot(y~lab,data=df1,ylab="Ceramic Strength",xlab="Laboratory")
title("Batch Number 1")

## Create a dataframe with batch 2 data and generate the box plot.
df2 = df[df$batch==2,]
boxplot(y~lab,data=df2,ylab="Ceramic Strength",xlab="Laboratory")
title("Batch Number 2")

############################
## Analyses for 1.4.2.10.5 #
############################

## Generate DEX scatter plot for batch 1.
batch = factor(m[,14])

## Restructure data so that x1, x2, and x3 are in a single column.
## Also, save re-coded version of the factor levels for DEX mean plot.
tempx  = x1
tempxc = x1 + 1
dm1 = cbind(y,lab,batch,tempx,tempxc)
tempx  = x2
tempxc = x2 + 4
dm2 = cbind(y,lab,batch,tempx,tempxc)
tempx  = x3
tempxc = x3 + 7
dm3 = cbind(y,lab,batch,tempx,tempxc)
dm4 = rbind(dm1,dm2,dm3)

## Generate factor ID variable.
n = length(y)
varind = c(rep("Table Speed",n),rep("Feed Rate",n),rep("Wheel Grit Size",n))
varind = as.factor(varind)

## Create a dataframe with "stacked" factors and data.
df = data.frame(dm4,varind)

## Create a dataframe for batch 1 data.
df1 = df[df$batch==1,]

## Attach lattice library and generate the DEX scatter plot.
library(lattice)
xyplot(y~tempx|varind,data=df1,layout=c(3,1),xlim=c(-2,2),
       ylab="Ceramic Strength",xlab="Factor Levels",
       main="Batch 1")

## Comute grand mean for batch 1.
ybar = mean(m[ m[,14]==1,5])

## Generate DEX mean plot.
interaction.plot(df1$tempxc,df1$varind,df1$y,fun=mean,
                 ylab="Ceramic Strength",xlab="",main="Batch 1 Means",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=ybar)

## Comute overall standard deviation for batch 1.
sdy = sd(m[ m[,14]==1,5])

## Generate DEX standard deviation plot.
interaction.plot(df1$tempxc,df1$varind,df1$y,fun=sd,
                 ylab="Ceramic Strength",xlab="",
                 main="Batch 1 Standard Deviations",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=sdy)

## Create a dataframe with batch 2 data.
df2 = df[df$batch==2,]

## Attach lattice library and generate the DEX scatter plot.
library(lattice)
xyplot(y~tempx|varind,data=df2,layout=c(3,1),xlim=c(-2,2),
       ylab="Ceramic Strength",xlab="Factor Levels",
       main="Batch 2")

## Comute grand mean for batch 2.
ybar = mean(m[ m[,14]==2,5])

## Generate DEX mean plot.
interaction.plot(df2$tempxc,df2$varind,df2$y,fun=mean,
                 ylab="Ceramic Strength",xlab="",main="Batch 2 Means",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=ybar)

## Comute grand mean for batch 2.
sdy = sd(m[ m[,14]==2,5])

## Generate DEX standard deviation plot.
interaction.plot(df2$tempxc,df2$varind,df2$y,fun=sd,
                 ylab="Ceramic Strength",xlab="",
                 main="Batch 2 Standard Deviations",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Table Speed","Feed Rate","Wheel Grit Size")
axis(side=1,at=xpos,labels=xlabel)
abline(h=sdy)

## DEX Interaction Plot for Batch 1 

## Create dataframe.
x12 = x1*x2
x13 = x1*x3
x23 = x2*x3
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
fx12 = factor(x12)
fx13 = factor(x13)
fx23 = factor(x23)
dfip = data.frame(y,batch,fx1,fx2,fx3,fx12,fx13,fx23)

## Create a dataframe for batch 1 data.
dfip1 = dfip[dfip$batch==1,]

## Compute overall batch mean.
ybar1 = mean(dfip1$y)

## Compute effect estimates and factor means.
q = aggregate(x=dfip1$y,by=list(dfip1$fx1),FUN="mean")
x1lo = q[1,2]
x1hi = q[2,2]
e1 = x1lo-x1hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx2),FUN="mean")
x2lo = q[1,2]
x2hi = q[2,2]
e2 = x2lo - x2hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx3),FUN="mean")
x3lo = q[1,2]
x3hi = q[2,2]
e3 = x3lo - x3hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx12),FUN="mean")
x12lo = q[1,2]
x12hi = q[2,2]
e12 = x12lo - x12hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx13),FUN="mean")
x13lo = q[1,2]
x13hi = q[2,2]
e13 = x13lo - x13hi

q = aggregate(x=dfip1$y,by=list(dfip1$fx23),FUN="mean")
x23lo = q[1,2]
x23hi = q[2,2]
e23 = x23lo - x23hi

## Create factor labels from effect values.
e = round(c(e3,e2,e23,e1,e12,e13),2)
textlabs = c("X3 Effect =","X2 Effect =","X2*X3 Effect =",
             "X1 Effect =","X1*X2 Effect =","X1*X3 Effect =")
labs = paste(textlabs,e)
group = factor(c(1:6),labels=labs)

## Create data frame with factor level means.
x = c(x3lo,x2lo,x23lo,x1lo,x12lo,x13lo)
xlev = rep(-1,6)
xlo = cbind(x,xlev,group)

x = c(x3hi,x2hi,x23hi,x1hi,x12hi,x13hi)
xlev = rep(1,6)
xhi = cbind(x,xlev,group)

m = rbind(xlo,xhi)
m = as.data.frame(m)

## Customize Lattice plot layout and color.
sp = c(T,T,F,T,F,F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)

## Generate plot.
xyplot(x~xlev | group, data=m, type="b", xlim=c(-2,2),
       layout=c(3,3), skip=sp, col=c(4), 
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=labs,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Strength", main="Batch 1",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = ybar1, lty = 2, col = 2)
}
)

## DEX Interaction Plot for Batch 2

## Create a dataframe for batch 2 data.
dfip2 = dfip[dfip$batch==2,]

## Compute overall batch mean.
ybar2 = mean(dfip2$y)

## Compute effect estimates and factor means.
q = aggregate(x=dfip2$y,by=list(dfip2$fx1),FUN="mean")
x1lo = q[1,2]
x1hi = q[2,2]
e1 = x1lo-x1hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx2),FUN="mean")
x2lo = q[1,2]
x2hi = q[2,2]
e2 = x2lo - x2hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx3),FUN="mean")
x3lo = q[1,2]
x3hi = q[2,2]
e3 = x3lo - x3hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx12),FUN="mean")
x12lo = q[1,2]
x12hi = q[2,2]
e12 = x12lo - x12hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx13),FUN="mean")
x13lo = q[1,2]
x13hi = q[2,2]
e13 = x13lo - x13hi

q = aggregate(x=dfip2$y,by=list(dfip2$fx23),FUN="mean")
x23lo = q[1,2]
x23hi = q[2,2]
e23 = x23lo - x23hi

## Create factor labels from effect values.
e = round(c(e3,e2,e23,e1,e12,e13),2)
textlabs = c("X3 Effect =","X2 Effect =","X2*X3 Effect =",
             "X1 Effect =","X1*X2 Effect =","X1*X3 Effect =")
labs = paste(textlabs,e)
group = factor(c(1:6),labels=labs)

## Create data frame with factor level means.
x = c(x3lo,x2lo,x23lo,x1lo,x12lo,x13lo)
xlev = rep(-1,6)
xlo = cbind(x,xlev,group)

x = c(x3hi,x2hi,x23hi,x1hi,x12hi,x13hi)
xlev = rep(1,6)
xhi = cbind(x,xlev,group)

m = rbind(xlo,xhi)
m = as.data.frame(m)

## Customize Lattice plot layout and color.
sp = c(T,T,F,T,F,F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)

## Generate plot.
xyplot(x~xlev | group, data=m, type="b", xlim=c(-2,2),
       layout=c(3,3), skip=sp, col=c(4), 
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=labs,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Strength", main="Batch 2",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = ybar2, lty = 2, col = 2)
}
)



#R commands and output:

alpha = 0.05
J = 6
K = 6
F = qf(1-alpha, J-1, K*(J-1))
F

#> [1] 2.533555
#R commands:

## Read data from file.
x <- read.table("../res/mass.dat", header=FALSE, skip=25)
colnames(x) <- c("date_year", "std_id", "std_value","balance_id", 
                 "std_dev", "design_id")

## Compute pooled standard deviation.
sp=sqrt(mean(x$std_dev^2))

## Determine control limit.
f = sqrt(qf(.99,3,351))
sul = f*sp

## Generate control chart with reference lines.
plot(x$date_year, x$std_dev, cex.sub=0.9,
     xlab="Time, years", ylab="Standard Deviation, micrograms",
     main="Control Chart for Precision for Balance #12",
     sub="Standard deviations with 3 degrees of freedom plotted vs year")
abline(h=sp)
abline(h=sul, lty=2,col="dark green")
text(86,0.072,"Control limit = 0.067 micrograms",cex=0.9)

#R commands:

## Read data from data file.
x <- read.table("../res/mass.dat", header=FALSE, skip=25)
colnames(x) <- c("date_year", "std_id", "std_value","balance_id", 
                 "std_dev", "design_id")

## Generate control limits based on years prior to 1985.
mn = mean(x[x$date_year<85,3])
std =  sd(x[x$date_year<85,3])
lcl = mn - 3*std
ucl = mn + 3*std

## Generate control chart with reference lines.
par(bg=rgb(1,1,0.8))
plot(x$date_year, x$std_value, ylim=c(-19.6,-19.3),
     xlab="Time, years", ylab="Corrections, micrograms",
     main="Shewhart control chart for kilogram calibrations")
abline(h=mn)
abline(h=lcl,lty=2,col="dark green")
abline(h=ucl,lty=2,col="dark green")
text(80, ucl+.006, cex=0.8,
     paste("UCL = mean + 3s =", round(ucl, digits=2)," micrograms"))
text(80, lcl-.006, cex=0.8,
     paste("LCL = mean - 3s =", round(lcl, digits=2)," micrograms")) 

## Generate control limits based on years after 1985.
amn = mean(x[x$date_year>85,3])
astd =  sd(x[x$date_year>85,3])
alcl = amn - 3*astd
aucl = amn + 3*astd

## Define colors for plotting.
color <- rep("black", nrow(x))
color[x[,1] <= 85] <- "black"
color[x[,1] > 85] <- "dark green"
	
## Generate revised control chart.
par(bg=rgb(1,1,0.8))
plot(x[,1], x[,3], type="p", col=color, 
     xlim=c(75,90), ylim=c(-19.6,-19.3), 
     main="Revised control chart for kilogram calibrations", 
     xlab="Time, years", ylab="Corrections, micrograms")
segments(x0=75,y0=mn,x1=85,y1=mn)
segments(x0=85,y0=amn,x1=90,y1=amn)
segments(x0=75,y0=lcl,x1=85,y1=lcl,lty=2,col="dark green")
segments(x0=85,y0=alcl,x1=90,y1=alcl,lty=2,col="dark green")
segments(x0=75,y0=ucl,x1=85,y1=ucl,lty=2,col="dark green")
segments(x0=85,y0=aucl,x1=90,y1=aucl,lty=2,col="dark green")
text(87.5, aucl+0.006, paste("UCL = ", round(aucl,2),"micrograms"), cex=0.8)
text(87.5, alcl-0.006, paste("LCL = ", round(alcl,2),"micrograms"), cex=0.8)
#R commands:

## Read data from file.
x = read.table("../res/mass.dat", header=FALSE, skip=4)
colnames(x) = c("date_year", "std_id", "std_value","balance_id", 
                 "std_dev", "design_id")

## Index of the limit for historical data.
ind = which(x[,1] > 85)
ind85 = ind[1]
color = rep("black", nrow(x))
color[x[,1] <= 85] = "black"
color[x[,1] > 85] = "dark green"
	
## Generate EWMA chart.
par(bg=rgb(1,1,0.8))
plot(x[,1], x[,3], type="p", pch=4, col=color, xlim=c(75,92), 
     main=expression( paste( "EWMA control chart for mass calibrations, ", 
     lambda," = 0.2") ), xlab="Time in years", ylab="Corrections (mg)")

## Year limit for historical data.
abline(v=85, col="dark green")

## Compute the average of the historical data
target = mean(x[1:(ind85-1),3])
segments(x0=75, y0=target, x1=x[nrow(x),1], y1=target, col="dark green")
text(x[nrow(x),1], target, paste("target = ", as.character(round(target, 
     digits=3))),	pos=4, cex=0.8, col="dark green")

## Standard deviation of the historical data.
s = sd(x[1:(ind85-1),3])	
lambda = 0.2
k = 3

## Compute the upper control limit.
ucl = target + s*k*sqrt(lambda / (2-lambda))
segments(x0=85, y0=ucl, x1=x[nrow(x),1], y1=ucl, col="red")
text(x[nrow(x),1], ucl, paste("UCL = ", as.character(round(ucl, digits=3))),
	pos=4, cex=0.8, col="red")

## Compute the lower control limit.
lcl = target - s*k*sqrt(lambda / (2-lambda))
segments(x0=85, y0=lcl, x1=x[nrow(x),1], y1=lcl, col="red")
text(x[nrow(x),1], lcl, paste("LCL = ", as.character(round(lcl, digits=3))),
	pos=4, cex=0.8, col="red")

## Determine EWMA signals.
iter = 1
meani = array(target,dim=length(ind))
for (i in ind)
{
	yi = x[i,3]
	meanip1 = lambda*yi + (1 - lambda)*meani[iter]
	iter = iter+1
	meani[iter] = meanip1
}
points(x[ind,1], meani[1:iter-1], type="p", pch=20, col="black")
points(x[ind,1], meani[1:iter-1], type="l", lwd=2, col="black")

#R commands and output:

alpha = 0.05
k = 6
t = qt(1-alpha/2, k-1)
t

#> [1] 2.570582

#R commands and output:

## Read the data and define variables.
m = matrix(scan("../res/loadcell.dat",skip=2),ncol=2,byrow=T)
y = m[,2]
x = m[,1]
x2 = x^2

## Fit the quadratic model.
z = lm(y ~ x + x2)
summary(z)

#> Call:
#> lm(formula = y ~ x + x2)

#> Residuals:
#>        Min         1Q     Median         3Q        Max 
#> -9.966e-05 -1.466e-05  5.944e-06  2.515e-05  5.595e-05 

#> Coefficients:
#>               Estimate Std. Error   t value Pr(#>|t|)    
#> (Intercept) -1.840e-05  2.451e-05    -0.751    0.459    
#> x            1.001e-01  4.839e-06 20687.891   <2e-16 ***
#> x2           7.032e-06  2.014e-07    34.922   <2e-16 ***
#> ---
#> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

#> Residual standard error: 3.764e-05 on 30 degrees of freedom
#> Multiple R-squared:     1,      Adjusted R-squared:     1 
#> F-statistic: 4.48e+09 on 2 and 30 DF,  p-value: < 2.2e-16

## Perform lack-of-fit test.
lof = lm(y~factor(x))

## Print results.
anova(z,lof)

#> Analysis of Variance Table

#> Model 1: y ~ x + x2
#> Model 2: y ~ factor(x)
#>   Res.Df        RSS Df  Sum of Sq      F Pr(#>F)
#> 1     30 4.2504e-08                            
#> 2     22 3.7733e-08  8 4.7700e-09 0.3477 0.9368



#R commands and output:

## Read data and save variables.
m = matrix(scan("../res/loadcell.dat",skip=25),ncol=2,byrow=T)
x = m[,1]
y = m[,2]
x2 = x*x

## Generate quadratic regression curve and print results.
z = lm(y ~ x + x2)
zz = summary(z)
zz

#> Call:
#> lm(formula = y ~ x + x2)

#> Residuals:
#>        Min         1Q     Median         3Q        Max 
#> -9.966e-05 -1.466e-05  5.944e-06  2.515e-05  5.595e-05 

#> Coefficients:
#>               Estimate Std. Error   t value Pr(#>|t|)    
#> (Intercept) -1.840e-05  2.451e-05    -0.751    0.459    
#> x            1.001e-01  4.839e-06 20687.891   <2e-16 ***
#> x2           7.032e-06  2.014e-07    34.922   <2e-16 ***
#> ---
#> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

#> Residual standard error: 3.764e-05 on 30 degrees of freedom
#> Multiple R-squared:     1,      Adjusted R-squared:     1 
#> F-statistic: 4.48e+09 on 2 and 30 DF,  p-value: < 2.2e-16 

## Print covariance matrix.
v = vcov(z)
v

#>               (Intercept)             x            x2
#> (Intercept)  6.006038e-10 -1.076163e-10  4.019870e-12
#> x           -1.076163e-10  2.341301e-11 -9.506940e-13
#> x2           4.019870e-12 -9.506940e-13  4.054636e-14

## Save coefficients and variances.
a = z$coef[1]
b = z$coef[2]
c = z$coef[3]
sa2 = v[1,1]
sb2 = v[2,2]
sc2 = v[3,3]
sy2 = zz$sigma**2

## Generate additional points on the x-axis for plotting.
xnew = seq(2,21,by=.1)
xnew2 = xnew^2
xp = data.frame(x=xnew,x2=xnew2)

## Predict response for given X' values.
yp = predict(z,new=xp)

## Generate calibration curve plot.
plot(x,y, main="Quadratic Calibration Curve for Load Cell 32066",
     xlab="Load, psi", ylab="Readings")
lines(xp$x,yp)
llab = paste("Y = ", round(a,7), " + ", round(b,7),
             "*X + ", round(c,7), "*X*X",sep="")
text(8,2,llab)
segments(x0=0,y0=1.344,x1=13.417,y1=1.344,lty=2,col="blue")
text(6,1.4, "Y'=1.344",col="blue")
segments(x0=13.417,y0=1.344,x1=13.417,y1=0,lty=2,col="blue")
text(15,0.6, "X'=13.417",col="blue")

## The equation for the quadratic calibration curve is:
## f = sqrt(-b + (b^2 - 4*c*(a-y)))/(2*c)
## The partial derivatives of f with respect to Y is:

dfdy = 1/sqrt(b^2 - 4*c*(a-y))

## The other partial derivatives are:

dfda = -1/sqrt(b^2 - 4*c*(a-y))

dfdb = (-1 + b/sqrt(b^2 - 4*c*(a-y)))/(2*c)

dfdc = (-4*a + 4*y)/(sqrt(b^2 - 4*c*(a-y))*(4*c)) - 
       (-b + sqrt(b^2 - 4*c*(a-y)))/(2*c^2)

## The standard deviation of X' is defined from propagation of error. 
u = sqrt(dfdy^2*sy2 + dfda^2*sa2 + dfdb^2*sb2 + dfdc^2*sc2)

## Plot uncertainty versus X'.
plot(y,u,type="n",xlab="Scale for Instrument Response",
     ylab="psi",
     main="Standard deviation of calibrated value X' for a given response Y'")
lines(spline(y,u))

## Print the covariance matrix for the loadcell data.
v

#>               (Intercept)             x            x2
#> (Intercept)  6.006038e-10 -1.076163e-10  4.019870e-12
#> x           -1.076163e-10  2.341301e-11 -9.506940e-13
#> x2           4.019870e-12 -9.506940e-13  4.054636e-14

## Save covariances.
sab = v[1,2]
sac = v[1,3]
sbc = v[2,3]

## Compute updated uncertainty.
unew = sqrt(u^2 + 2*dfda*dfdb*sab + 2*dfda*dfdc*sac + 2*dfdb*dfdc*sbc)

## Plot predicted value versus X'.
plot(y,unew,type="n",xlab="Scale for Instrument Response",
     ylab="psi",
     main="Standard deviation of calibrated value X' for a given response Y'")
lines(spline(y,unew))


#R commands and output:

## Read data and define variables.
m = read.table("../res/linewid.dat", header=FALSE, skip=2)
colnames(m) = c("day", "pos", "x", "y") 

## Specify regression coefficients from calibration experiment.
b0 = 0.2357
b1 = 0.9870

## Compute the calibration standard deviation.
w = ((m$y - b0)/b1) - m$x 
sdcal = sd(w)

## The calibration standard deviation is:
sdcal

#> [1] 0.1193572
#R commands and output:

## Read data and save relevant variables.
m = matrix(scan("../res/calibrationline.dat", skip = 25),ncol=5,byrow=T)
x = m[,1]
y = m[,2]

## Fit the linear calibration model and print the estimated
## coefficients.
z = lm(y ~ x)
zz = summary(z)
zz$coefficients

#>              Estimate Std. Error    t value     Pr(#>|t|)
#> (Intercept) 0.2357623 0.02430034   9.702014 7.860745e-12
#> x           0.9870377 0.00344058 286.881171 5.354121e-65

## print the covariance matrix.
v = vcov(z)
v

#>               (Intercept)             x
#> (Intercept)  5.905067e-04 -7.649453e-05
#> x           -7.649453e-05  1.183759e-05

## Save model parameters and variances in convenient variables.
a = z$coef[1]
b = z$coef[2]
sa2 = v[1,1]
sb2 = v[2,2]
sab = v[1,2]
sy2 = zz$sigma^2

## Generate new Y' values for plotting.
ynew = seq(0,12,by=.25)

## Compute uncertainty for values of y.
u2 = sa2/b^2 + (ynew-a)^2*sb2/b^4 + sy2/b^2 + 2*(ynew-a)*sab/b^3
u = sqrt(u2)

## Plot uncertainty versus Y'.
plot(ynew,u,type="l",xlab="Instrument Response, micrometers",
     ylab="micrometers",
     main="Standard deviation of calibrated value X' for a given response Y'")

#R commands and output:

alpha = 0.05
m = 3
v = 38
zeta = .5*(1 - exp(log(1-alpha)/m))
TSTAR = qt(zeta, v, lower.tail=FALSE)
TSTAR

#> [1] 2.497575#R commands:

## Read the data.
m = read.table(linewid.dat, header=FALSE, skip=2)
day = m[,1]
position = m[,2]
x = m[,3]
y = m[,4]

## Define the initial calibration experiment.
intercept = 0.2357	## intercept
slope = 0.9870		## slope
sd = 0.06203		## residual standard deviation

df = 38		      ## degrees of freedom
alpha = 0.05	      ## significance level
m = 3		            ## linear calibration line at 3 points

## Percentile for t* critical value.
zeta = 0.5*(1 - exp(log(1 - alpha)/m))	

## Find the upper quantile of Student distribution.
tstar = qt(p=zeta, df=df, lower.tail=FALSE)

## Control values of the calibration.
w = ((y - intercept)/slope) - x
center = 0

## Generate the control chart.
par(bg=rgb(1,1,0.8), oma=c(4, 0, 0, 0))
plot(day, w, type="p", pch=8, xlim=c(0,10), ylim=c(-0.3,0.4),
	main="Control chart for optical imaging system",
	xlab="Time in days", ylab=expression(paste("control values ( ",mu,"m)")),
	xaxs="i", yaxs="i")
axis(1,1:10)
segments(x0=1, y0=center, x1=9.75, y1=center)

## Compute upper and lower control limits.
lcl = center + sd*tstar/slope
ucl = center - sd*tstar/slope
	
## Add control limits to plot.
segments(x0=1, y0=ucl, x1=6, y1=ucl, col=grey(0.7))
segments(x0=6, y0=ucl, x1=9.75, y1=ucl, lty="dashed")
segments(x0=1, y0=lcl, x1=6, y1=lcl, col=grey(0.7))
segments(x0=6, y0=lcl, x1=9.75, y1=lcl, lty="dashed")

## Add subtitle and text to plot.
title(outer=TRUE, line=1,sub= "Linewidths corrected for linear calibration
control values at lower, mid, and upper range of calibration interval")
text(8,0,srt=45,col="gray","future control values")


#R commands and output:

## Read the data and save relevant variables.
m <- read.table("../res/mpc411.dat", header=FALSE, skip=2)
run = m[,1]
day = m[,5]
stddev = m[,9]
df = m[,10]

sumofsquare = df*stddev*stddev
sumofsumofsquare = sum(sumofsquare)
sumdf = sum(df)
s1 = (sumofsumofsquare/sumdf)^0.5

print(cbind(run, day, df, stddev, sumofsquare))

#>	      run day df stddev sumofsquare
#>	 [1,]   1  15  5 0.1024  0.05242880
#>	 [2,]   1  17  5 0.0943  0.04446245
#>	 [3,]   1  18  5 0.0622  0.01934420
#>	 [4,]   1  22  5 0.0702  0.02464020
#>	 [5,]   1  23  5 0.0627  0.01965645
#>	 [6,]   1  24  5 0.0622  0.01934420
#>	 [7,]   2  12  5 0.0996  0.04960080
#>	 [8,]   2  18  5 0.0533  0.01420445
#>	 [9,]   2  19  5 0.0364  0.00662480
#>	[10,]   2  19  5 0.0768  0.02949120
#>	[11,]   2  20  5 0.1042  0.05428820
#>	[12,]   2  21  5 0.0868  0.03767120

print(paste("total degrees of freedom for s1:", sumdf))

#>	[1] "total degrees of freedom for s1: 60"

print(paste("total sum of squares for s1:", sumofsumofsquare))

#>	[1] "total sum of squares for s1: 0.37175695"

print(paste("pooled value for the repeatability standard deviation:", 
      format(s1,digits=3)))

#>	[1] "pooled value for the repeatability standard deviation: 0.0787"
#R commands and output:

## Read the data.
m <- read.table("../res/mpc411.dat", header=FALSE, skip=2)
run = m[,1]
wafer = m[,2]
probe = m[,3]
month = m[,4]
day = m[,5]
op = m[,6]
temp = m[,7]
avg = m[,8]
stddev = m[,9]
df = m[,10]

## Differentiate between the two runs.
n1 = which(run[] == 1)
n2 = which(run[] == 2)

## Compute the level-2 standard deviation.
sdrun1 = sd(avg[n1])
dofsdrun1 = length(n1) - 1
sdrun2 = sd(avg[n2])
dofsdrun2 = length(n2) - 1
sumofsquare = (dofsdrun1*sdrun1**2 + dofsdrun2*sdrun2**2)
dofs2 = length(n1) + length(n2) - 2

## Level-2 pooled standard deviation.
s2 = sqrt(sumofsquare / dofs2)

## Print results.
qsd = rbind(sdrun1,sdrun2,s2)
qdof = rbind(dofsdrun1,dofsdrun2,dofs2)
s = data.frame(qdof,qsd)
names(s) = c( "Degrees of Freedom","   Standard Deviation")
row.names(s) = c("Run 1", "Run 2", "Pooled Level 2")
s

#>                Degrees of Freedom    Standard Deviation
#> Run 1                           5            0.02727935
#> Run 2                           5            0.02756307
#> Pooled Level 2                 10            0.02742157

## Compute the between-day standard deviation.
J = 6
sumofsquare1 = df*stddev*stddev
sumofsumofsquare = sum(sumofsquare1)
sumdf = sum(df)
s1 = (sumofsumofsquare/sumdf)^0.5
vardays = s2**2 - s1**2/J

## Print results.
print(paste("between-day variance:", round(vardays,8)))

#> [1] "between-day variance: -0.00028072"


#R commands and output:

## Read data.
data = "s:/sed/jsplett/r_Handbook/data/mpc61.dat"
m = read.table(data, header=FALSE)

## Save relevant data for probe #2362 in a data frame.
m = m[m[,3]==2362,]
frun = as.factor(m[,1])
fwafer = as.factor(m[,2])
avg = m[,8]
df = data.frame(frun,fwafer,avg)

## Compute means for each run and wafer combination.
mns = aggregate(df$avg, by = list(df$frun, df$fwafer), FUN = "mean")

## Compute meanas for each wafer.
mnw = aggregate(df$avg, by = list(df$fwafer), FUN = "mean")

## Compute s3 for each wafer
ss = array(0, dim=c(length(mnw[,1]))) 
for( i in 1:length(mnw[,1]))
{
id = mnw$Group.1[i]
ss[i] = sum((mns[mns$Group.2==id,3] - mnw[mnw$Group.1==id,2])^2)
}

## Print results.
dof = rep(1,length(mnw[,1]))
Statistics = cbind(unique(m[,2]),round(sqrt(ss),4),dof,round(ss,7))
colnames(Statistics)= c("Wafer", "s3", "v", "v*s3*s3")
data.frame(Statistics)

#>   Wafer     s3 v      s3.v
#> 1   138 0.0222 1 0.0004946
#> 2   139 0.0027 1 0.0000073
#> 3   140 0.0288 1 0.0008323
#> 4   141 0.0133 1 0.0001764
#> 5   142 0.0205 1 0.0004191 

print(paste("SS =",round(sum(ss),7)),quote=FALSE)

#> [1] SS = 0.0019297

print(paste("Pooled Value, s3 =", round(sqrt(sum(ss)/length(ss)),4)),
      quote=FALSE)

#> [1] Pooled Value, s3 = 0.0196

#R commands and output:

## Read data.
m = read.table("../res/mpc411.dat", header=FALSE, skip=2)
run = m[,1]
avg = m[,8]

## Differentiate between the two runs.
n1 = which(run[] == 1)
n2 = which(run[] == 2)

## Compute averages.
meanrun1 = mean(avg[n1])
meanrun2 = mean(avg[n2])
mean = ( meanrun1 + meanrun2 ) / 2

## Compute level-3 standard deviation.
sumofsquare = (meanrun1 - mean)^2 + (meanrun2 - mean)^2
nu = 1
s3 = sqrt( sumofsquare / nu )

## Print results.
print(paste("level-3 standard deviation:", round(s3,6)))
###>[1] "level-3 standard deviation: 0.02885"

print(paste("degree of freedom:", nu))
###> [1] "degree of freedom: 1"


#R commands and output:

## Read the data and define variables.
m = read.table(mpc536.dat, header=FALSE)
wafer = m[,1]
day = m[,2]
probe = m[,3]
d1 = m[,4]
d2 = m[,5]

## Definition of the wafer ID vector for plotting.
pchMat = vector("integer", length=nrow(m))
num = 49
pchMat[] = num

for( i in 2:nrow(m) ){
	if(wafer[i] != wafer[i-1]){
		num = num + 1
		pchMat[i:nrow(m)] = num} }

## Plot the differences between wiring configurations for run 1.
par(mfrow=c(2,1),bg=rgb(1,1,0.8))
plot(c(1:nrow(m)), d1, type="p", pch=pchMat, 
	xlab= "sequence for 5 wafers and 6 days", ylab="difference in ohm.cm")
title("Difference between 2 wiring configurations, run 1") 
segments(x0=0, y0=0, x1=30, y1=0, col="dark orange")
text(1, min(d1), "* coded by wafer ID", pos=4, cex=0.8, col="red")

## Plot the differences between wiring configurations for run 2.
plot(c(1:nrow(m)), d2, type="p", pch=pchMat, 
	xlab= "sequence for 5 wafers and 6 days", ylab="difference in ohm.cm")
title("Difference between 2 wiring configurations, run 2") 
segments(x0=0, y0=0, x1=30, y1=0, col="dark orange")
text(1, min(d2), "* coded by wafer ID", pos=4, cex=0.8, col="red")

## Compute average difference for each run.
avgrun1 = mean(d1)
avgrun2 = mean(d2)

## Compute standard deviation for each run.
sdrun1 = sd(d1)
sdrun2 = sd(d2)
	
## t-test statistic for difference between configurations
t1 = sqrt(nrow(m)-1)*avgrun1/sdrun1
t2 = sqrt(nrow(m)-1)*avgrun2/sdrun2

## Print results.
avg = rbind(avgrun1,avgrun2)
std = rbind(sdrun1,sdrun2)
tstat = rbind(t1,t2)
round(data.frame(avg,std,tstat),6)

#>               avg      std     tstat
#> avgrun1 -0.003834 0.005145 -3.943518
#> avgrun2  0.004886 0.004004  6.456969

## quantile function for the t-distribution
t = qt(p=0.975, df=nrow(m)-1)
print(paste("t critical value =", round(t,3)))

#> [1] "t critical value = 2.048"#R commands and output:

## Read data and add column for degrees of freedom.
m <- read.table("../res/mpc61.dat", header=FALSE)
colnames(m) <- c("run","wafer","probe","month","day","op","temp",
                 "avg","stddev")
m$dof = rep(5,length(m$avg))

## Level 1 standard deviation for probe 2362.

## Save run 1 and run 2 data in different matrices.
m1p = m[m$probe==2362&m$run==1,]
dof1 = sum(m1p$dof)
m2p = m[m$probe==2362&m$run==2,]
dof2 = sum(m2p$dof)

## Compute pooled standard deviations for each run and all data.
sp1 = sqrt(sum(m1p$dof*m1p$stddev^2)/dof1)
sp2 = sqrt(sum(m2p$dof*m2p$stddev^2)/dof2)
sp = sqrt((dof1*sp1^2 + dof2*sp2^2)/(dof1 + dof2))

## Print results.
probe = "2362"
x = data.frame(probe,round(sp1,5),dof1,round(sp2,5),dof2,
               round(sp,5),dof1+dof2)
names(x) = c("Probe", "Run 1", "DF", "Run 2", "DF", "Pooled", "DF")
x

#>   Probe   Run 1  DF   Run 2  DF  Pooled  DF
#> 1  2362 0.06751 150 0.07786 150 0.07287 300

## Level 2 standard deviations for probe 2362.

## Compute Run 1 means and standard deviations for each wafer.
fwafer1 = as.factor(m1p$wafer)
mn1 = m1p[,8]
df1 = data.frame(fwafer1,mn1)
wmn1 = aggregate(df1$mn1,list(df1$fwafer1),mean)
wsd1 = aggregate(df1$mn1,list(df1$fwafer1),sd)

## Compute Run2 means and standard deviations for each wafer.
fwafer2 = as.factor(m2p$wafer)
mn2 = m2p[,8]
df2 = data.frame(fwafer2,mn2)
wmn2 = aggregate(df2$mn2,list(df2$fwafer2),mean)
wsd2 = aggregate(df2$mn2,list(df2$fwafer2),sd)

## Print results.
dof = rep(5,length(wmn1[,1]))
probe = rep(2362,length(wmn1[,1]))
stats = data.frame(probe, unique(m1p[,2]), wmn1$x, round(wsd1$x,5), dof,
         wmn2$x, round(wsd2$x,5),dof)
colnames(stats) = c("Probe", "Wafer", "Mean1", "Std1", "DOF1",
                     "Mean2", "Std2", "DOF2")
stats

#>   Probe Wafer     Mean1    Std1 DOF1     Mean2    Std2 DOF2
#> 1  2362   138  95.09282 0.03594    5  95.12427 0.04532    5
#> 2  2362   139  99.30595 0.04722    5  99.30978 0.02147    5
#> 3  2362   140  96.03573 0.02728    5  96.07653 0.02756    5
#> 4  2362   141 101.06022 0.02319    5 101.07900 0.05369    5
#> 5  2362   142  94.21482 0.02744    5  94.24377 0.03698    5

## Compute pooled standard deviation across wafers.

sdf1 = sum(stats$DOF1)
sp1 = sqrt(sum(stats$DOF1*stats$Std1^2)/sdf1)

sdf2 = sum(stats$DOF2)
sp2 = sqrt(sum(stats$DOF2*stats$Std2^2)/sdf2)

## Print results.
z = data.frame(round(sp1,5), sdf1, round(sp2,5), sdf2)
names(z) = c("Run 1", "df", "Run 2", "df")
z

#>     Run 1 df   Run 2 df
#> 1 0.03334 25 0.03879 25

## Compute pooled standard deviation across runs.
s2 = sqrt((sdf1*sp1^2 + sdf2*sp2^2)/(sdf1 + sdf2))

## Print results.
zz = c(paste("Pooled standard deviation over two runs =",round(s2,5)),
       paste("Degrees of freedom =", (sdf1+sdf2)))
print(zz,quote=FALSE)

#> [1] Pooled standard deviation over two runs = 0.03617
#> [2] Degrees of freedom = 50


## Level 3 standard deviatons for probe 2362.

newdf = rbind(wmn1,wmn2)
s3 = aggregate(newdf$x,list(newdf$Group.1),sd)
diff = wmn1$x - wmn2$x

sp3 = cbind(probe, unique(m1p[,2]), wmn1$x, wmn2$x, round(diff,5), 
           round(s3$x,5), rep(1,length(diff)))
colnames(sp3) = c("Probe", "Wafer", "Mean1", "Mean2", "Diff", "STDDEV", "DOF")
sp3

#>      Probe Wafer     Mean1     Mean2     Diff  STDDEV DOF
#> [1,]  2362   138  95.09282  95.12427 -0.03145 0.02224   1
#> [2,]  2362   139  99.30595  99.30978 -0.00383 0.00271   1
#> [3,]  2362   140  96.03573  96.07653 -0.04080 0.02885   1
#> [4,]  2362   141 101.06022 101.07900 -0.01878 0.01328   1
#> [5,]  2362   142  94.21482  94.24377 -0.02895 0.02047   1

zz = rbind(paste("Pooled standard deviation =", round(sqrt(mean(s3$x^2)),4)),
       paste("df =", sum(sp3[,7])))
print(zz,quote=FALSE)

#>      [,1]                              
#> [1,] Pooled standard deviation = 0.0196
#> [2,] df = 5   


## Save variables as factors and create data frame.
fwafer = as.factor(m$wafer)
fprobe = as.factor(m$probe)
frun = as.factor(m$run)
df = data.frame(fwafer,frun,fprobe,m$avg)

## Compute cell means.
mn = aggregate(df$m.avg,list(df$frun,df$fprobe,df$fwafer),mean)
wmn = aggregate(df$m.avg,list(df$frun,df$fwafer),mean)

## Compute differences from wafer means for each run.
d = array(0, dim=c(length(mn[,1]))) 
wm = array(0, dim=c(length(mn[,1]))) 
for( i in 1:length(mn[,1]))
{
id = mn$Group.3[i]
rid = mn$Group.1[i]
wm[i] = wmn[wmn$Group.1==rid & wmn$Group.2==id,3]
d[i] = mn[i,4] - wm[i]
}
mn$diff = d

## Separate data frame into run 1 and run 2.
mn1 = mn[mn$Group.1==1,]
mn2 = mn[mn$Group.1==2,]

## Print results.
ddf = data.frame(mn1$Group.3,mn1$Group.2,round(mn1$diff,4),
                 round(mn2$diff,4))
names(ddf) = c("Wafer", "Probe","Run 1","Run 2")
ddf

#>    Wafer Probe   Run 1   Run 2
#> 1    138     1  0.0247 -0.0119
#> 2    138   281  0.0108  0.0323
#> 3    138   283  0.0192 -0.0258
#> 4    138  2062 -0.0175  0.0561
#> 5    138  2362 -0.0372 -0.0508
#> 6    139     1 -0.0035 -0.0006
#> 7    139   281  0.0395  0.0051
#> 8    139   283  0.0057  0.0239
#> 9    139  2062 -0.0323  0.0373
#> 10   139  2362 -0.0094 -0.0657
#> 11   140     1  0.0400  0.0109
#> 12   140   281  0.0187  0.0106
#> 13   140   283 -0.0201  0.0002
#> 14   140  2062 -0.0126  0.0181
#> 15   140  2362 -0.0261 -0.0398
#> 16   141     1  0.0393  0.0325
#> 17   141   281 -0.0107 -0.0037
#> 18   141   283  0.0246 -0.0190
#> 19   141  2062 -0.0280  0.0436
#> 20   141  2362 -0.0252 -0.0534
#> 21   142     1  0.0062  0.0094
#> 22   142   281  0.0376  0.0174
#> 23   142   283 -0.0044  0.0193
#> 24   142  2062 -0.0011  0.0008
#> 25   142  2362 -0.0383 -0.0469


## Save important variables.
run = m[,1]
wafer = m[,2]
probe = m[,3]
month = m[,4]
day = m[,5]
op = m[,6]
temp = m[,7]
avg = m[,8]
stddev = m[,9]

## Generate a new codes for day and probe.
daynum = rep(1:6,50)
probenum = rep(rep(1:5,each=6),10)

## Save all data for plotting in a data frame.
df = data.frame(run,probe,probenum,stddev,wafer,day,daynum)

## Save run #1 data in a new data frame.
df1 = subset(df,run==1)

## Generate new wafer variable for plotting and add to df1 data frame.
df1$waferd = df1$wafer + (df1$daynum-3.5)/10

## Attach lattice library and generate plot for run #1 and probe #2362.
library(lattice)
xyplot(df1$stddev[df$probe==2362]~df1$waferd[df$probe==2362], 
       data=df1, groups=df1$daynum[df$probe==2362],
       main="Gauge Study Repeatability Standard Deviations by Wafer and Day", 
       sub="Code for Days: A, B, C, D, E, F",
       ylab="Standard Deviation, ohm.cm", xlab="Wafer",
       pch=c("A","B","C","D","E","F"), cex=1.2)


## Save run #1 data in a new data frame.
df2 = subset(df,run==2)

## Generate new wafer variable for plotting and add to df2 data frame.
df2$waferd = df2$wafer + (df2$daynum-3.5)/10

## Generate plot for run #2 and probe #2362.
xyplot(df2$stddev[df$probe==2362]~df2$waferd[df$probe==2362], 
       data=df2, groups=df2$daynum[df$probe==2362],
       main="Gauge Study Repeatability Standard Deviations by Wafer and Day", 
       sub="Code for Days: A, B, C, D, E, F",
       ylab="Standard Deviation, ohm.cm", xlab="Wafer",
       pch=c("A","B","C","D","E","F"), cex=1.2)


## Generate new wafer variable for plotting and add to df1 data frame.
df1$waferp = df1$wafer + (df1$probenum-3)/10

## Generate plot
xyplot(df1$stddev~df1$waferp, data=df1, groups=df1$probe,
       main="Gauge Study Repeatability Standard Deviations by Wafer and Day", 
       sub="Code for probe: 1=#1, 2=#281, 3=#283, 4=#2062, 5=#2362",
       ylab="Standard Deviation, ohm.cm", xlab="Wafer",
       pch=c("1","2","3","4","5"), cex=1.2)


## Generate new wafer variable for plotting and add to df2 data frame.
df2$waferp = df2$wafer + (df2$probenum-3)/10

## Generate plot
xyplot(df2$stddev~df2$waferp, data=df2, groups=df2$probe,
       main="Gauge Study Repeatability Standard Deviations by Wafer and Day", 
       sub="Code for probe: 1=#1, 2=#281, 3=#283, 4=#2062, 5=#2362",
       ylab="Standard Deviation, ohm.cm", xlab="Wafer",
       pch=c("1","2","3","4","5"), cex=1.2)

## Generate plot for wafer 138.

mwafer138probe2362run1 <- subset(m, wafer==138 & probe==2362 & run==1)
mwafer138probe2362run2 <- subset(m, wafer==138 & probe==2362 & run==2)

plot(mwafer138probe2362run1$month + mwafer138probe2362run1$day/30,
     mwafer138probe2362run1$avg, type="b", pch=4, xlim=c(3,5), 
     ylim=c(95,95.2), xlab= "Time in months", ylab="average in ohm.cm", 
     xaxs="i",yaxs="i")
points(mwafer138probe2362run2$month + mwafer138probe2362run2$day/30,
       mwafer138probe2362run2$avg, type="b", pch=4)
text(3.5, 95.02, "run 1", pos=4, col="red")
text(4.5, 95.02, "run 2", pos=4, col="red")
title("Averages of resistivity measurements for Wafer 138 and Probe 2362")


## Generate plot for wafer 139.

mwafer139probe2362run1 <- subset(m, wafer==139 & probe==2362 & run==1)
mwafer139probe2362run2 <- subset(m, wafer==139 & probe==2362 & run==2)

plot(mwafer139probe2362run1$month + mwafer139probe2362run1$day/30,
     mwafer139probe2362run1$avg, type="b", pch=4, xlim=c(3,5), 
     ylim=c(99.2,99.4),	xlab= "Time in months", ylab="average in ohm.cm", 
     xaxs="i",yaxs="i")
points(mwafer139probe2362run2$month + mwafer139probe2362run2$day/30,
       mwafer139probe2362run2$avg, type="b", pch=4)
text(3.5, 99.22, "run 1", pos=4, col="red")
text(4.5, 99.22, "run 2", pos=4, col="red")
title("Averages of resistivity measurements for Wafer 139 and Probe 2362")


## Generate plot for wafer 140.

mwafer140probe2362run1 <- subset(m, wafer==140 & probe==2362 & run==1)
mwafer140probe2362run2 <- subset(m, wafer==140 & probe==2362 & run==2)

plot(mwafer140probe2362run1$month + mwafer140probe2362run1$day/30,
     mwafer140probe2362run1$avg, type="b", pch=4, xlim=c(3,5), 
     ylim=c(95.9,96.2), xlab= "Time in months", ylab="average in ohm.cm", 
     xaxs="i",yaxs="i")
points(mwafer140probe2362run2$month + mwafer140probe2362run2$day/30,
       mwafer140probe2362run2$avg, type="b", pch=4)
text(3.5, 95.92, "run 1", pos=4, col="red")
text(4.5, 95.92, "run 2", pos=4, col="red")
title("Averages of resistivity measurements for Wafer 140 and Probe 2362")


## Generate plot for wafer 141.

mwafer141probe2362run1 <- subset(m, wafer==141 & probe==2362 & run==1)
mwafer141probe2362run2 <- subset(m, wafer==141 & probe==2362 & run==2)

plot(mwafer141probe2362run1$month + mwafer141probe2362run1$day/30,
     mwafer141probe2362run1$avg, type="b", pch=4, xlim=c(3,5), 
     ylim=c(100.9,101.2), xlab= "Time in months", ylab="average in ohm.cm", 
     xaxs="i",yaxs="i")
points(mwafer141probe2362run2$month + mwafer141probe2362run2$day/30,
       mwafer141probe2362run2$avg, type="b", pch=4)
text(3.5, 100.92, "run 1", pos=4, col="red")
text(4.5, 100.92, "run 2", pos=4, col="red")
title("Averages of resistivity measurements for Wafer 141 and Probe 2362")


## Generate plot for wafer 142.

mwafer142probe2362run1 <- subset(m, wafer==142 & probe==2362 & run==1)
mwafer142probe2362run2 <- subset(m, wafer==142 & probe==2362 & run==2)

plot(mwafer142probe2362run1$month + mwafer142probe2362run1$day/30,
     mwafer142probe2362run1$avg, type="b", pch=4, xlim=c(3,5), 
     ylim=c(94.1,94.35), xlab= "Time in months", 
     ylab="average in ohm.cm", xaxs="i",yaxs="i")
points(mwafer142probe2362run2$month + mwafer142probe2362run2$day/30,
       mwafer142probe2362run2$avg, type="b", pch=4)
text(3.5, 94.12, "run 1", pos=4, col="red")
text(4.5, 94.12, "run 2", pos=4, col="red")
title("Averages of resistivity measurements for Wafer 142 and Probe 2362")


## Run 1 - Graph of differences from wafer averages for 
## each of 5 probes

mpr1 <- subset(m, run==1)
mean1 <- array(0, dim=c(length(unique(mpr1$probe)), 
               length(unique(mpr1$wafer))))
plotwafer1 <- array(0, dim=c(length(unique(mpr1$probe)), 
                    length(unique(mpr1$wafer))))

for( i in 1:length(unique(mpr1$probe)) )
{
    for( j in 1:length(unique(mpr1$wafer)) )
    {
    plotwafer1[i,j] <- unique(mpr1$wafer)[j]
    mean1[i,j] <- mean(mpr1$avg[which(mpr1$probe == unique(mpr1$probe)[i] 
                       & mpr1$wafer == unique(mpr1$wafer)[j])])
    }
}
meanofmeans1 <- apply(mean1,2,mean)

plot(plotwafer1[1,], mean1[1,]-meanofmeans1, type="b", lty=3, pch=49,
     xlim=c(137,143), ylim=c(-0.04,0.04),
     xlab= "Wafer number", ylab="ohm.cm")
for(i in 2:length(unique(mpr1$probe)) )
{
    points(plotwafer1[i,], mean1[i,]-meanofmeans1, type="b", lty=3, pch=48+i)
}
segments(138,0,142,0)
title("Differences among Probes vs Wafer (run 1)")

## Run 2 - Graph of differences from wafer averages for 
## each of 5 probes 

mpr2 <- subset(m, run==2)
mean2 <- array(0, dim=c(length(unique(mpr2$probe)), 
               length(unique(mpr2$wafer))))
plotwafer2 <- array(0, dim=c(length(unique(mpr2$probe)), 
              length(unique(mpr2$wafer))))

for( i in 1:length(unique(mpr2$probe)) )
{
    for( j in 1:length(unique(mpr2$wafer)) )
    {
    plotwafer2[i,j] <- unique(mpr2$wafer)[j]
    mean2[i,j] <- mean(mpr2$avg[which(mpr2$probe == unique(mpr2$probe)[i] 
                       & mpr2$wafer == unique(mpr2$wafer)[j])])
    }
}
meanofmeans2 <- apply(mean2,2,mean)

plot(plotwafer2[1,], mean2[1,]-meanofmeans2, type="b", lty=3, pch=49,
     xlim=c(137,143), ylim=c(-0.08,0.08),
     xlab= "Wafer number", ylab="ohm.cm")
for(i in 2:length(unique(mpr2$probe)) )
{
    points(plotwafer2[i,], mean2[i,]-meanofmeans2, type="b", lty=3, pch=48+i)
}
segments(138,0,142,0)




#R commands and output:

## Input data and save relevant variables.
m <- read.table("../res/mpc62.dat", skip=14)
colnames(m) <- c("crystalID","stdID","month","day","hour","minute",
                 "op","humidity","probeID","temp","chkstd","stddev","df")
day = m[,4]
stddev = m[,12]
df = m[,13]

## Compute the level-1 standard deviation.
sumofsquare = df*stddev*stddev
sumofsumofsquare = sum(sumofsquare)
sumdf = sum(df)
s1 = (sumofsumofsquare/sumdf)**0.5
round(s1,5)

#> [1] 0.06139

## Compute the level-2 standard deviation.
s2 = sd(m$chkstd)
round(s2,5)

#> [1] 0.0268


## Compute the upper quantile of the F distribution.
f1 <- qf(0.95, 5, 125)
f1

#> [1] 2.286771

## Compute the upper Control Limit
ucl1 <- s1*f1**0.5
round(ucl1,5)

#> [1] 0.09283

## Generate control chart for bias and variability.
center = mean(m$chkstd)
ucl = center + 2*s2
lcl = center - 2*s2

print(paste("LCL=", round(lcl,5), " Center=",round(center,5),
      " UCL=",round(ucl,5)), quote=FALSE)

#> [1] LCL= 97.01624  Center= 97.06984  UCL= 97.12344


## Generate day variable for plotting.
indday <- c(24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11)
dayw <- vector(mode="integer", length=length(day))
for(i in 1:length(day)){
  dayw[i] <- which(indday == day[i])}

## Compute center line.
meanstddev <- sqrt(mean(stddev*stddev))

## Compute the level 1 standard deviation.
sumofsquare = df*stddev*stddev
sumofsumofsquare = sum(sumofsquare)
sumdf = sum(df)
s1 = (sumofsumofsquare/sumdf)**0.5

## Compute the upper quantile of the F distribution.
f1 <- qf(0.95, 5, 125)

## Compute the upper Control Limit
ucl1 <- s1*f1**0.5

## Generate the control chart for precision.
plot(dayw, m$stddev, pch=1, xlab="Time in days", 
     ylab="standard deviation in ohm.cm",
     xlim=c(0,20),ylim=c(0.02,0.12))
segments(min(dayw),meanstddev, max(dayw),meanstddev)
segments(min(dayw),ucl1, max(dayw),ucl1, lty="dashed")
title("Control chart for precision \n 
     (Standard deviations with probe #2362, 5% upper control limit)")

## Generate day variable for plotting.
indday <- c(24,25,26,27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11)
dayw <- vector(mode="integer", length=length(day))
for(i in 1:length(day)){
  dayw[i] <- which(indday == day[i])}

## Compute center line.
meanchkstd <- mean(m$chkstd)

## Compute level-2 standard deviation
s2 <- sd(m$chkstd)

## Compute upper and lower control limits.
ucl2 <- meanchkstd + 2*s2
lcl2 <- meanchkstd - 2*s2

## Generate the control chart for bias and long-term variability.
plot(dayw, m$chkstd, pch=1, xlab="Time in days", 
     ylab="Measurement of check standard in ohm.cm",
     xlim=c(0,20),ylim=c(97,97.2))
segments(min(dayw),meanchkstd, max(dayw),meanchkstd)
segments(min(dayw),ucl2, max(dayw),ucl2, lty="dashed")
segments(min(dayw),lcl2, max(dayw),lcl2, lty="dashed")
title("Shewhart control chart \n 
     (Check standard 137 for probe #2362, 2-sigma control limits)")


#R commands and output:

## Read data and add column for degrees of freedom.
m <- read.table("../res/mpc61.dat", skip=50)
colnames(m) <- c("run","wafer","probe","month","day","op","temp",
                 "avg","stddev")
m$dof = rep(5,length(m$avg))
probe = "2362"

## Level 1 standard deviation for probe 2362.

## Save run 1 and run 2 data in different matrices.
m1p = m[m$probe==2362&m$run==1,]
d1 = sum(m1p$dof)
m2p = m[m$probe==2362&m$run==2,]
d2 = sum(m2p$dof)

## Compute pooled standard deviations for each run and all data.
sp1 = sqrt(sum(m1p$dof*m1p$stddev^2)/d1)
sp2 = sqrt(sum(m2p$dof*m2p$stddev^2)/d2)
dof1 = d1 + d2
s1 = sqrt((d1*sp1^2 + d2*sp2^2)/dof1)


## Level 2 standard deviations for probe 2362.

## Compute Run 1 means and standard deviations for each wafer.
fwafer1 = as.factor(m1p$wafer)
mn1 = m1p[,8]
df1 = data.frame(fwafer1,mn1)
wmn1 = aggregate(df1$mn1,list(df1$fwafer1),mean)
wsd1 = aggregate(df1$mn1,list(df1$fwafer1),sd)

## Compute Run2 means and standard deviations for each wafer.
fwafer2 = as.factor(m2p$wafer)
mn2 = m2p[,8]
df2 = data.frame(fwafer2,mn2)
wmn2 = aggregate(df2$mn2,list(df2$fwafer2),mean)
wsd2 = aggregate(df2$mn2,list(df2$fwafer2),sd)

## Save results in a data frame.
dof = rep(5,length(wmn1[,1]))
probe = rep(2362,length(wmn1[,1]))
stats = data.frame(probe, unique(m1p[,2]), wmn1$x, round(wsd1$x,5), dof,
         wmn2$x, round(wsd2$x,5),dof)
colnames(stats) = c("Probe", "Wafer", "Mean1", "Std1", "DOF1",
                     "Mean2", "Std2", "DOF2")

## Compute pooled standard deviation across wafers.

sdf1 = sum(stats$DOF1)
sp1 = sqrt(sum(stats$DOF1*stats$Std1^2)/sdf1)

sdf2 = sum(stats$DOF2)
sp2 = sqrt(sum(stats$DOF2*stats$Std2^2)/sdf2)

## Compute pooled standard deviation across runs.
dof2 = sdf1 + sdf2
s2 = sqrt((sdf1*sp1^2 + sdf2*sp2^2)/dof2)


## Level 3 standard deviatons for probe 2362.

newdf = rbind(wmn1,wmn2)
s3 = aggregate(newdf$x,list(newdf$Group.1),sd)
diff = wmn1$x - wmn2$x

sp3 = cbind(probe, unique(m1p[,2]), wmn1$x, wmn2$x, round(diff,5), 
           round(s3$x,5), rep(1,length(diff)))
colnames(sp3) = c("Probe", "Wafer", "Mean1", "Mean2", "Diff", "STDDEV", "DOF")

dof3 = sum(sp3[,7])
s3 = sqrt(mean(s3$x^2))

## Print summary table.
lev = c("Level-1","Level-2","Level-3")
symb = c("s1","s2","s3")
est = c(s1,s2,s3)
deg = c(dof1,dof2,dof3)
zzz = data.frame(lev,symb,round(est,4),deg)
colnames(zzz) = c("Level","Symbol","Estimate","DF")
zzz

#>     Level Symbol Estimate  DF
#> 1 Level-1     s1   0.0729 300
#> 2 Level-2     s2   0.0362  50
#> 3 Level-3     s3   0.0196   5


## Calculate individual components for days and runs

sdays = sqrt(s2^2 -s1^2/6)
sdays

#> [1] 0.02057092

sruns = sqrt(s3^2 - s2^2/6)
sruns

#> [1] 0.01295841


## Correction for bias or probe #2362 and uncertainty

## Save variables as factors and create data frame.
fwafer = as.factor(m$wafer)
fprobe = as.factor(m$probe)
frun = as.factor(m$run)
df = data.frame(fwafer,frun,fprobe,m$avg)

## Compute cell means.
mn = aggregate(df$m.avg,list(df$frun,df$fprobe,df$fwafer),mean)
wmn = aggregate(df$m.avg,list(df$frun,df$fwafer),mean)

## Compute differences from wafer means for each run.
d = array(0, dim=c(length(mn[,1]))) 
wm = array(0, dim=c(length(mn[,1]))) 
for( i in 1:length(mn[,1]))
{
id = mn$Group.3[i]
rid = mn$Group.1[i]
wm[i] = wmn[wmn$Group.1==rid & wmn$Group.2==id,3]
d[i] = mn[i,4] - wm[i]
}
mn$diff = d

## Separate data frame into run 1 and run 2.
mn1 = mn[mn$Group.1==1,]
mn2 = mn[mn$Group.1==2,]

## Print results for probe #2362.
ddf = data.frame(mn1$Group.3,mn1$Group.2,round(mn1$diff,4),
                 round(mn2$diff,4))
names(ddf) = c("Wafer", "Probe","Run 1","Run 2")
dfp = ddf[ddf$Probe==2362,]
dfp

#>    Wafer Probe   Run 1   Run 2
#> 5    138  2362 -0.0372 -0.0508
#> 10   139  2362 -0.0094 -0.0657
#> 15   140  2362 -0.0261 -0.0398
#> 20   141  2362 -0.0252 -0.0534
#> 25   142  2362 -0.0383 -0.0469

rbind(paste("Run 1 Average =", round(mean(dfp[,3]),4)),
paste("Run 2 Average =", round(mean(dfp[,4]),4)),
paste("Overall Average =", round(mean(c(dfp[,3],dfp[,4])),4)),
paste("Overall Standard Deviation =", round(sd(c(dfp[,3],dfp[,4])),4)) )

#>      [,1]                                 
#> [1,] "Run 1 Average = -0.0272"            
#> [2,] "Run 2 Average = -0.0513"            
#> [3,] "Overall Average = -0.0393"          
#> [4,] "Overall Standard Deviation = 0.0162"

## Save sprobe for later use.
sprobe = sd(c(dfp[,3],dfp[,4]))
dfprobe = length(c(dfp[,3],dfp[,4]))-1


## Read data.
m <- read.table("../res/check_std.dat", skip=50)
colnames(m) <- c("wafer","probe","cona1","cona1s","conb1","conb1s",
                 "cona2","cona2s","conb2","conb2s")

## Compute differences between configurations.
diff1 = m$cona1 - m$conb1
diff2 = m$cona2 - m$conb2

## Test for significant differences between configurations.
t1 = t.test(diff1)
t2 = t.test(diff2)

## Print results.
Status = c("Pre","Post")
Average = round(c(mean(diff1),mean(diff2)),4)
Stddev = round(c(sd(diff1),sd(diff2)),4)
DF = c(length(diff1)-1,length(diff2-1))
t = round(c(t1$statistic,t2$statistic),2)
data.frame(Status,Average,Stddev,DF,t)

#>   Status Average Stddev DF     t
#> 1    Pre -0.0086 0.0242 29 -1.94
#> 2   Post -0.0119 0.0354 30 -1.84


## Standard uncertainty includes components for 
## repeatability, days, runs and probe

u = sqrt(5*s2^2/6 + s3^2 + sprobe^2/10)
u

#> [1] 0.03875842


## Approximate degrees of freedom and expanded uncertainty

a = c(0,sqrt(5/6),1,sqrt(1/10))
s = c(s1,s2,s3,sprobe)
df = c(dof1,dof2,dof3,dfprobe)
v = round(u^4 / sum((a^4)*(s^4)/df))
v

#> [1] 42

round(qt(0.975,v)*u,4)

#> [1] 0.0782


## Read data.
m <- read.table("../res/check_std.dat",skip=50)
colnames(m) <- c("wafer", "probe", "avgArun1", "sdArun1", "avgBrun1", 
                 "sdBrun1","avgArun2", "sdArun2", "avgBrun2", "sdBrun2")

## Define the probe ID vector as:  1 = 50, ..., 5 = 54.
SortWafer <- sort(unique(m$wafer))

## Generate plot for Run 1.
plot(c(1:nrow(m)), m$avgArun1 - m$avgBrun1, 
     pch=48 + match(m$wafer,SortWafer),
     xlab="Run order", ylab="ohm.cm",
     xlim=c(0,31), ylim=c(-0.1,0.1), col="dark green")
segments(1,0, nrow(m),0, col="dark green")
title("Difference between wiring configurations A and B")
text(2, 0.1, 
"Wafer legend \n 1 = 138 \n 2 = 139 \n 3 = 140 \n 4 = 141 \n 5 = 142 ",
pos=1, cex=0.8)
text(28, 0.1, "Run 1", pos=1, col="dark green")

## Generate plot for Run 2.
plot(c(1:nrow(m)), m$avgArun2 - m$avgBrun2, 
     pch=48 + match(m$wafer,SortWafer),
     xlab="Run order", ylab="ohm.cm",
     xlim=c(0,31), ylim=c(-0.1,0.1), col="dark green")
segments(1,0, nrow(m),0, col="dark green")
title("Difference between wiring configurations A and B")
text(2, 0.1, 
"Wafer legend \n 1 = 138 \n 2 = 139 \n 3 = 140 \n 4 = 141 \n 5 = 142 ",
pos=1, cex=0.8)
text(28, 0.1, "Run 2", pos=1, col="dark green")
[Desktop Entry]
Encoding=UTF-8
Name=Link to 3.5.1. Furnace Case Study
Type=Link
URL=file:///home/aghiles/S11/code/R/doc/handbook/ppc/section5/ppc51.html
Icon=text-html
Name[en_US]=ppc510
#R commands and output:

## Read data and save relevant variables.
m = matrix(scan("../res/furnace.dat",skip=25),ncol=4,byrow=T)
thickness = m[,4]

## Generate summary statistics for thickness.
mnt = mean(thickness)
sdt = sd(thickness)
n = length(thickness)
stderr = sdt/sqrt(n)

## Generate plots of the data.
library(Hmisc)
par(mfrow = c(2, 2))
qqnorm(thickness,main="")
boxplot(thickness,ylab="Film Thickness (ang.)")
x = thickness
hist(x,main="", xlab="Film Thickness (ang.)", freq=FALSE, ylim=c(0,0.02),
     breaks=15)
curve(dnorm(x, mean = mnt, sd=sdt), col = 2, lwd = 2, add = TRUE)

## Compute 95 % confidence interval for the mean.
df = n-1
alpha = 0.05
Tvalue = qt(1-alpha/2,df=df)
Lower = mnt - Tvalue*stderr
Upper = mnt + Tvalue*stderr
ci = c(round(mnt,5), round(Lower,5), round(Upper,5))

## Compute 95 % confidence interval for the variance.
chilower = qchisq(alpha/2, df)
chiupper = qchisq(alpha/2, df, lower.tail = FALSE)
v = var(thickness)
vci = c(round(sdt,5),round(sqrt(df * v/chiupper),5), 
                     round(sqrt(df * v/chilower),5))
 
## Print confidence intervals.
q = data.frame(rbind(ci,vci))
names(q)= c("Estimate", "Lower CI Bound", "Upper CI Bound")
row.names(q) = c("Mean","Stan. Dev.")
q

#>            Estimate Lower CI Bound Upper CI Bound
#> Mean       563.03571      559.16916      566.90227
#> Stan. Dev.  25.38468       22.92967       28.43306

## Compute and print thickness quantiles.
p = c(0,0.5,2.5,10,25,50,75,90,95,97.5,99.5,100)/100
Quantiles = round(quantile(thickness,probs=p,type=6),2)
as.data.frame(Quantiles)

#>       Quantiles
#> 0%       487.00
#> 0.5%     487.00
#> 2.5%     514.23
#> 10%      532.90
#> 25%      546.25
#> 50%      562.50
#> 75%      582.75
#> 90%      595.00
#> 95%      608.10
#> 97.5%    615.10
#> 99.5%    634.00
#> 100%     634.00

## Define target, USL, and LSL.
USL = 660
LSL = 460
Target = 560
ult = c(LSL, USL, Target)

## Compute Cp and a 95 % confidence interval.
Cpi = (USL - LSL)/(6*sdt)
Cp_cilo = Cpi*sqrt(qchisq(alpha/2, df)/df)
Cp_ciup = Cpi*sqrt(qchisq(1-alpha/2, df)/df)
Cp = round(c(Cpi, Cp_cilo, Cp_ciup),3)

## Compute CpL and a 95 % confidence interval.
CpLi = (mnt - LSL)/(3*sdt)
CpL_se = sqrt(1/(9*n) + (CpLi**2)/(2*df))
CpL_cilo = CpLi - qnorm(1-alpha/2)*CpL_se 
CpL_ciup = CpLi + qnorm(1-alpha/2)*CpL_se
CpL = round(c(CpLi, CpL_cilo, CpL_ciup),3)

## Compute CpU and a 95 % confidence interval.
CpUi = (USL - mnt)/(3*sdt)
CpU_se = sqrt(1/(9*n) + (CpUi**2)/(2*df))
CpU_cilo = CpUi - qnorm(1-alpha/2)*CpU_se 
CpU_ciup = CpUi + qnorm(1-alpha/2)*CpU_se
CpU = round(c(CpUi, CpU_cilo, CpU_ciup),3)

## Compute Cpk and a 95 % confidence interval.
Cpki = min(CpL,CpU)
Cpk_se = sqrt(1/(9*n) + (Cpki**2)/(2*df))
Cpk_cilo = Cpki - qnorm(1-alpha/2)*Cpk_se 
Cpk_ciup = Cpki + qnorm(1-alpha/2)*Cpk_se
Cpk = round(c(Cpki, Cpk_cilo, Cpk_ciup),3)

## Compute Cpm and a 95 % confidence interval.
Cpmi = (USL - LSL)/(6*sqrt(sdt**2 + (mnt - Target)**2))
Cpm_cilo = Cpmi * sqrt(qchisq(alpha/2, df)/df)
Cpm_ciup = Cpmi * sqrt(qchisq(1-alpha/2, df)/df)
Cpm = round(c(Cpmi, Cpm_cilo, Cpm_ciup),3)

## Save and print the capability indices.
Index = data.frame(rbind(Cp, CpL, CpU, Cpk, Cpm))
names(Index)= c("Estimate", "Lower CI", "Upper CI")
Index

#>     Estimate Lower CI Upper CI
#> Cp     1.313    1.172    1.454
#> CpL    1.353    1.199    1.507
#> CpU    1.273    1.128    1.419
#> Cpk    1.128    1.128    1.419
#> Cpm    1.304    1.164    1.443

## Compute actual percent defective.
defect_act_lt = 100*length(subset(thickness,thickness < LSL))/n
defect_act_gt = 100*length(subset(thickness,thickness > USL))/n
defect_act = 100*length(subset(thickness, 
                        thickness < LSL | thickness > USL))/n

## Compute theoretical percent defective assuming a normal distribution.
defect_theo_lt = 100*pnorm((LSL - mnt)/sdt)
defect_theo_gt = 100*pnorm((USL - mnt)/sdt,lower.tail=FALSE)
defect_theo = defect_theo_lt + defect_theo_gt

## Print percent defective.
Outside_LSL = round(cbind(LSL,defect_act_lt,defect_theo_lt),5)
Outside_USL = round(cbind(USL,defect_act_gt,defect_theo_gt),5)
Outside_Target = round(cbind(Target,defect_act,defect_theo),5)

results = data.frame(rbind(Outside_LSL, Outside_USL, Outside_Target))
names(results)= c("Value","% Actual", "% Theoretical")
row.names(results) = c("Outside LSL","Outside USL","Outside Target")
results

#>                Value % Actual % Theoretical
#> Outside LSL      460        0       0.00246
#> Outside USL      660        0       0.00668
#> Outside Target   560        0       0.00914

##########
## 3.5.1.3

## Define variables.
run = m[,1]
zone = m[,2]
wafer = m[,3]
thickness = m[,4]

## Generate box plot for each run.
par(mfrow=c(1,1))
df = data.frame(thickness,run,zone,wafer)
boxplot(thickness~run, data=df, ylab="Film Thickness (ang.)", xlab="Run",
        main="Box Plot by Run")
abline(h=mean(thickness))

## Generate box plot for each furnace location (zone).
df = data.frame(thickness,run,zone,wafer)
boxplot(thickness~zone, data=df, ylab="Film Thickness (ang.)",
        xlab="Furnace Location",
        main="Box Plot by Furnace Location")
abline(h=mean(thickness))

## Generate box plot for each wafer.
df = data.frame(thickness,run,zone,wafer)
boxplot(thickness~wafer, data=df, ylab="Film Thickness (ang.)",
        xlab="Wafer", main="Box Plot by Wafer")
abline(h=mean(thickness))

## Save variables as factors.
fact = as.factor((run*100 + zone)/100)
fwafer = factor(wafer)
df = data.frame(thickness,fact,fwafer)

## Compute the batch means for each laboratory.
avg = aggregate(x=df$thickness, by=list(df$fact,df$fwafer), FUN="mean")

## Generate the block plot.
## Specify locations of the bars on the x axis.
xpos = c(1:84)
boxplot(avg$x ~ avg$Group.1, medlty="blank", xlim=c(1,84), 
        boxwex=.05, varwidth=FALSE,
        ylab="Film Thickness (ang.)",
        xlab="Furnace Location Within Run",
        main="Block Plot by Furnace Location",
        at=xpos,xaxt="n")
axis(side=1,at=seq(2.5,82.5,by=4),
     labels=c("1","2","3","4","5","6","7","8","9","10","11",
              "12","13","14","15","16","17","18","19","20","21"))

## Add labels for the wafer means.
f1 = avg[avg$Group.2==1,3]
f2 = avg[avg$Group.2==2,3]
for(i in (1:length(f1))) {
  if(f1[i] > f2[i])
  {text(xpos[i],f1[i],labels="1", pos=3, cex=.5, offset=.15)
   text(xpos[i],f2[i],labels="2", pos=1, cex=.5, offset=.15)}
  else{text(xpos[i],f1[i],labels="1", pos=1, cex=.5, offset=.15)
       text(xpos[i],f2[i],labels="2", pos=3, cex=.5, offset=.15)}
}


##########
## 3.5.1.4

## Prepare data frame.
run = as.factor(m[,1])
zone = as.factor(m[,2])
df = data.frame(thickness,run,zone,wafer)

## Perform nested analysis of variance.
q = summary(aov(thickness ~ run + Error(run/zone), data=df))
q2 = unlist(q)

## Generate F tests.
F_value = q2[3]/q2[6]
p_value = pf(F_value, q2[1], q2[4], lower.tail = FALSE)
res1 = cbind(q2[1],q2[2],q2[3],F_value,p_value)
row.names(res1) = c("Run")

F_value = q2[6]/q2[11]
p_value = pf(F_value, q2[4], q2[9], lower.tail = FALSE)
res2 = cbind(q2[4],q2[5],q2[6],F_value,p_value)
row.names(res2) = c("Location(Run)")

## Print ANOVA table.
res3 = cbind(q2[9],q2[10],q2[11],NA,NA)
row.names(res3) = c("Within")
res = rbind(res1,res2,res3)
colnames(res) = c("DOF","SSE","MSE","F Ratio","Prob #> F")
res

#>               DOF      SSE       MSE  F Ratio     Prob #> F
#> Run            20 61442.29 3072.1143 5.374035 1.393903e-07
#> Location(Run)  63 36014.50  571.6587 4.728639 3.850360e-11
#> Within         84 10155.00  120.8929       NA           NA

## Compute variance components.
library("nlme")
fit.lme=lme(thickness ~ 1, random = ~ 1|run/zone, df, method="REML")
v = VarCorr(fit.lme)
vsub = matrix(as.numeric(v[c(2,4,5),]),ncol=2)

## Compute percent of total variation.
total = sum(vsub[,1])
percent = round(100*vsub[,1]/total,2)

## Print results
vc = data.frame(round(vsub,3),percent)
colnames(vc)= c("  Var. Comp.", "  Stan. Dev", "  % of Total") 
row.names(vc) = c("Run","Location(Run)", "Within")
vc

#>                 Var. Comp.   Stan. Dev   % of Total
#> Run                312.557      17.679        47.44
#> Location(Run)      225.381      15.013        34.21
#> Within             120.893      10.995        18.35



[Desktop Entry]
Encoding=UTF-8
Name=Link to 3.5.2. Machine Screw Case Study
Type=Link
URL=file:///home/aghiles/S11/code/R/doc/handbook/ppc/section5/ppc52.html
Icon=text-html
Name[en_US]=ppc520
#R commands and output:

## Read data and save relevant variables.
m = matrix(scan("../res/machine.dat",skip=25),ncol=5,byrow=T)
machine = m[,1]
day = m[,2]
time = m[,3]
sample = m[,4]
diameter = m[,5]

## Generate box plot for each machine.
df = data.frame(diameter,machine,day,time,sample)
boxplot(diameter~machine, data=df, ylab="Diameter (inches)", xlab="Machine",
        main="Box Plot by Machine")
abline(h=mean(diameter))

## Generate box plot for each day.
boxplot(diameter~day, data=df, ylab="Diameter (inches)", xlab="Day",
        main="Box Plot by Day")
abline(h=mean(diameter))

## Generate box plot for time of day.
boxplot(diameter~time, data=df, ylab="Diameter (inches)", xlab="Time of Day",
        main="Box Plot by Time of Day",names=c("AM","PM"))
abline(h=mean(diameter))

## Generate box plot by sample number.
boxplot(diameter~sample, data=df, ylab="Diameter (inches)", 
        xlab="Sample Number", main="Box Plot by Sample")
abline(h=mean(diameter))

## Save variables as factors.
machine = as.factor(m[,1])
day = as.factor(m[,2])
time = as.factor(m[,3])
sample = as.factor(m[,4])
diameter = m[,5]
df = data.frame(diameter,machine,day,time,sample)

## Perform ANOVA using all four factors.
summary(aov(diameter ~ machine+day+time+sample,data=df))

#>              Df     Sum Sq    Mean Sq F value    Pr(#>F)    
#> machine       2 1.1076e-04 5.5377e-05 29.3162 1.276e-11 ***
#> day           2 3.7340e-06 1.8670e-06  0.9884    0.3744    
#> time          1 2.3580e-06 2.3580e-06  1.2481    0.2655    
#> sample        9 8.8490e-06 9.8300e-07  0.5205    0.8583    
#> Residuals   165 3.1168e-04 1.8890e-06                      
#> ---
#> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

## Analysis of variance using machine only.
q = aov(diameter ~ machine,data=df)
qq = summary(q)
qq

#>              Df     Sum Sq    Mean Sq F value    Pr(#>F)    
#> machine       2 0.00011075 0.00005538   30.01 5.988e-12 ***
#> Residuals   177 0.00032662 0.00000185                      
#> ---
#> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

## Retrieve RMSE and residual degrees of freedom from the ANOVA table.
temp = unlist(qq)
rmse = sqrt(temp[6])
dof = temp[2]

## Compute summary statistics and 95 % confidence intervals for
## each machine.
alpha = 0.05
mns = aggregate(x=df$diameter,by=list(df$machine),FUN="mean")
n = aggregate(x=df$diameter,by=list(df$machine),FUN="length")
stderr = rmse / sqrt(n$x)
Tvalue = qt(1-alpha/2,df=dof)
lower = round(mns$x - Tvalue*stderr,5)
upper = round(mns$x + Tvalue*stderr,5)

## Print results.
s = data.frame(n$Group.1, n$x, round(mns$x,5), round(stderr,5), lower, upper)
names(s) = c("Level","n", "Mean", "Std. Err.", "Lower CI", "Upper CI")
s

#>   Level  n    Mean Std. Err. Lower CI Upper CI
#> 1     1 60 0.12489   0.00018  0.12454  0.12523
#> 2     2 60 0.12297   0.00018  0.12262  0.12331
#> 3     3 60 0.12402   0.00018  0.12368  0.12437

## Generate residuals from model with machine only.
res = diameter - predict(q)

## Generate 4-plot of residuals.
library(Hmisc)
par(mfrow = c(2, 2))
plot(res, xlab="Sequence", ylab="Residuals", main="Run Sequence Plot")
plot(res, Lag(res), xlab="Residual[i-1]", ylab="Residual[i]",
     main="Lag Plot")
hist(res, xlab="Residuals", ylab="Count", main="Histogram")
qqnorm(res, xlab="Theoretical Z-Scores", ylab="Residuals",
       main="Normal Probability Plot")

## Generate data frame with new cases.
tr = c(576, 604, 583, 657, 604, 586, 510, 546, 571)
day = as.factor(rep(1:3,3))
mach = as.factor(rep(1:3,each=3))
dfnew = data.frame(mach,day,tr)

## Print data table.
matrix(tr, nrow = 3, ncol = 3, byrow = TRUE,
       dimnames = list(c("Machine 1", "Machine 2", "Machine 3"),
                       c("Day 1", "Day 2", "Day3")) )

#>           Day 1 Day 2 Day3
#> Machine 1   576   604  583
#> Machine 2   657   604  586
#> Machine 3   510   546  571

## Generate plot.
machine = rep(1:3,each=3)
par(mfrow=c(1,1))
plot(machine, tr, ylab="Throughput", xlab="Machine",
     main="Throughput by Machine", 
     cex=1.25, xlim=c(.5,3.5), xaxp=c(1,3,2))
abline(h=mean(tr))
min = aggregate(x=dfnew$tr, by=list(dfnew$mach), FUN="min")
max = aggregate(x=dfnew$tr, by=list(dfnew$mach), FUN="max")
segments(as.numeric(min$Group.1),min$x,as.numeric(max$Group.1),max$x)

## Analysis of variance for throughput.
q = aov(tr ~ mach,data=dfnew)
qq = summary(q)
qq

#>             Df Sum Sq Mean Sq F value  Pr(#>F)  
#> mach         2 8216.9  4108.4  4.9007 0.05475 .
#> Residuals    6 5030.0   838.3                  
#> ---
#> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

## Retrieve RMSE and residual degrees of freedom from the ANOVA table.
temp = unlist(qq)
rmse = sqrt(temp[6])
dof = temp[2]

## Compute summary statistics and 95 % confidence intervals for
## each machine.
alpha = 0.05
mns = aggregate(x=dfnew$tr,by=list(dfnew$mach),FUN="mean")
n = aggregate(x=dfnew$tr,by=list(dfnew$mach),FUN="length")
stderr = rmse / sqrt(n$x)
Tvalue = qt(1-alpha/2,df=dof)
lower = round(mns$x - Tvalue*stderr,2)
upper = round(mns$x + Tvalue*stderr,2)

## Print results.
s = data.frame(n$Group.1, n$x, round(mns$x,2), round(stderr,2), lower, upper)
names(s) = c("Level","n", "Mean", "Std. Err.", "Lower CI", "Upper CI")
s

#>   Level n   Mean Std. Err. Lower CI Upper CI
#> 1     1 3 587.67     16.72   546.76   628.57
#> 2     2 3 615.67     16.72   574.76   656.57
#> 3     3 3 542.33     16.72   501.43   583.24


#R commands and output:

## Load cell calibration case study

## Create vector with dependent variable, deflection
deflection = c(0.11019, 0.21956, 0.32949, 0.43899, 0.54803, 0.65694,
               0.76562, 0.87487, 0.98292, 1.09146, 1.20001, 1.30822,
               1.41599, 1.52399, 1.63194, 1.73947, 1.84646, 1.95392,
               2.06128, 2.16844, 0.11052, 0.22018, 0.32939, 0.43886,
               0.54798, 0.65739, 0.76596, 0.87474, 0.98300, 1.09150,
               1.20004, 1.30818, 1.41613, 1.52408, 1.63159, 1.73965,
               1.84696, 1.95445, 2.06177, 2.16829)

## Create vector with independent variable, load
load = c(150000, 300000, 450000, 600000, 750000, 900000, 1050000,
         1200000, 1350000, 1500000, 1650000, 1800000, 1950000,
         2100000, 2250000, 2400000, 2550000, 2700000, 2850000,
         3000000, 150000, 300000, 450000, 600000, 750000, 900000,
         1050000, 1200000, 1350000, 1500000, 1650000, 1800000,
         1950000, 2100000, 2250000, 2400000, 2550000, 2700000,
         2850000, 3000000)

## Determine the number of observations
len = length(load)

## Generate regression analysis results
out = lm(deflection~load)
summary(out)

#> Call:
#> lm(formula = deflection ~ load)
#>
#> Residuals:
#>        Min         1Q     Median         3Q        Max 
#> -0.0042751 -0.0016308  0.0005818  0.0018932  0.0024211 
#>
#> Coefficients:
#>              Estimate Std. Error  t value Pr(#>|t|)    
#> (Intercept) 6.150e-03  7.132e-04    8.623 1.77e-10 ***
#> load        7.221e-07  3.969e-10 1819.289  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.002171 on 38 degrees of freedom
#> Multiple R-Squared:     1,      Adjusted R-squared:     1 
#> F-statistic:  3.31e+06 on 1 and 38 DF,  p-value: < 2.2e-16 

## Plot data overlaid with estimated regression function
par(mfrow=c(1,1),cex=1.25)
plot(load,deflection,xlab="Load",ylab="Deflection",
     pch=16, cex=1.25, col="blue" )
abline(reg=out)

## Plot residuals versus the independent variable, load
par(mfrow=c(1,1),cex=1.25)
plot(load,out$residuals, xlab="Load", ylab="Residuals",
     pch=16, cex=1.25, col="blue")

## Plot residual versus predicted values
par(mfrow=c(1,1),cex=1.25)
plot(out$fitted.values,out$residuals, 
     xlab="Predicted Values from the Straight-Line Model", 
     ylab="Residuals", pch=16, cex=1.25, col="blue")

## 4-Plot of residuals
par(mfrow=c(2,2))
plot(out$residuals,ylab="Residuals",xlab="Observation Number",
     main="Run Order Plot")
plot(out$residuals[2:len],out$residuals[1:len-1],ylab="Residuals",
     xlab="Lag 1 Residuals",main="Lag Plot")
hist(out$residuals,ylab="Frequency",xlab="Residuals",main="Histogram")
qqnorm(out$residuals,main="Normal Probability Plot")
par(mfrow=c(1,1))

## Perform lack-of-fit test
lof = lm(deflection~factor(load))

## Print results.
anova(out,lof)

#> Analysis of Variance Table
#> 
#> Model 1: deflection ~ load
#> Model 2: deflection ~ factor(load)
#>   Res.Df        RSS Df  Sum of Sq      F    Pr(#>F)    
#> 1     38 1.7915e-04                                   
#> 2     20 9.2200e-07 18 1.7823e-04 214.75 < 2.2e-16 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 

## Create variable with squared load
load2 = load*load

## Fit quadratic model
outq = lm(deflection~load + load2)
qq = summary(outq)
qq

#> Call:
#> lm(formula = deflection ~ load + load2)
#>
#> Residuals:
#>        Min         1Q     Median         3Q        Max 
#> -4.468e-04 -1.578e-04  3.817e-05  1.088e-04  4.235e-04 
#>
#> Coefficients:
#>               Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  6.736e-04  1.079e-04    6.24 2.97e-07 ***
#> load         7.321e-07  1.578e-10 4638.65  < 2e-16 ***
#> load2       -3.161e-15  4.867e-17  -64.95  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.0002052 on 37 degrees of freedom
#> Multiple R-Squared:     1,      Adjusted R-squared:     1 
#> F-statistic:  1.853e+08 on 2 and 37 DF,  p-value: < 2.2e-16

## Sort data for plotting
upred = deflection - outq$resid
udfout = data.frame(upred,load)
udfout = udfout[order(load),]

## Plot data overlaid with estimated regression function
par(mfrow=c(1,1),cex=1.25)
plot(load,deflection,xlab="Load",ylab="Deflection",
     pch=16, cex=1.25, col="blue")
lines(udfout$load,udfout$upred)

## Plot residuals versus independent variable, load
par(mfrow=c(1,1),cex=1.25)
plot(load,outq$residuals,xlab="Load",ylab="Residuals",
     pch=16, cex=1.25, col="blue")

## Plot residuals versus predicted deflection
par(mfrow=c(1,1),cex=1.25)
plot(outq$fitted.values,outq$residuals,
     ylab="Residuals",xlab="Predicted Values from Quadratic Model",
     pch=16, cex=1.25, col="blue")

## 4-Plot of residuals
par(mfrow=c(2,2))
plot(outq$residuals,ylab="Residuals",xlab="Observation Number",
     main="Run Order Plot")
plot(outq$residuals[2:len],outq$residuals[1:len-1],ylab="Residuals",
     xlab="Lag 1 Residuals",main="Lag Plot")
hist(outq$residuals,ylab="Frequency",xlab="Residuals",main="Histogram")
qqnorm(outq$residuals,main="Normal Probability Plot")
par(mfrow=c(1,1))

## Perform lack-of-fit test
lof = lm(deflection~factor(load))

## Print results.
anova(outq,lof)

#> Analysis of Variance Table
#>
#> Model 1: deflection ~ load + load2
#> Model 2: deflection ~ factor(load)
#>   Res.Df        RSS Df  Sum of Sq      F Pr(#>F)
#> 1     37 1.5576e-06                            
#> 2     20 9.2215e-07 17 6.3547e-07 0.8107 0.6662

## Solve the regression function for Load
nd = 1.239722
tval = qt(.975,outq$df.residual)
f = function(load) {outq$coef%*%c(1,load,load^2)-nd}
nl = uniroot(f,c(min(load),max(load)))$root
nl

#> [1] 1705106

## Plot regression line and desired calibration point
par(mfrow=c(1,1),cex=1.25,srt=0)
plot(load,deflection,ylab="Deflection",xlab="Load",
     pch=16, cex=1.25, col="blue")
abline(h=nd)
text(750000,1.3,"Deflection = 1.239722")
abline(v=nl)
par(srt=-90)
text(1800000,.7,"Load = ???")

## Compute confidence interval for calibration value 
## Create function to calculate the upper lmit
lo = function(load){
rsdm = sqrt(1 + c(1,load,load^2)%*%qq$cov.unscaled%*%c(1,load,load^2))
f(load) + tval*qq$sigma*rsdm
}

## Create function to calculate the lower limit
up = function(load){
rsdm = sqrt(1 + c(1,load,load^2)%*%qq$cov.unscaled%*%c(1,load,load^2))
f(load) - tval*qq$sigma*rsdm
}

## Use the two functions to find the roots
local = uniroot(lo,lower=min(load),upper=max(load))
local$root

#> [1] 1704513

upcal = uniroot(up,lower=min(load),upper=max(load))
upcal$root

#> [1] 1705698


#R commands and output:

## Alaska pipeline ultrasonic calibration case study

## Create vector with dependent variable, field defect size
fdef = c(18,38,15,20,18,36,20,43,45,65,43,38,33,10,50,10,50,15,53,60,18,
         38,15,20,18,36,20,43,45,65,43,38,33,10,50,10,50,15,53,15,37,15,
         18,11,35,20,40,50,36,50,38,10,75,10,85,13,50,58,58,48,12,63,10,
         63,13,28,35,63,13,45,9,20,18,35,20,38,50,70,40,21,19,10,33,16,5,
         32,23,30,45,33,25,12,53,36,5,63,43,25,73,45,52,9,30,22,56,15,45)

## Create vector with independent variable, lab defect size
ldef = c(20.2,56.0,12.5,21.2,15.5,39.0,21.0,38.2,55.6,81.9,39.5,56.4,40.5,
         14.3,81.5,13.7,81.5,20.5,56.0,80.7,20.0,56.5,12.1,19.6,15.5,38.8,
         19.5,38.0,55.0,80.0,38.5,55.8,38.8,12.5,80.4,12.7,80.9,20.5,55.0,
         19.0,55.5,12.3,18.4,11.5,38.0,18.5,38.0,55.3,38.7,54.5,38.0,12.0,
         81.7,11.5,80.0,18.3,55.3,80.2,80.7,55.8,15.0,81.0,12.0,81.4,12.5,
         38.2,54.2,79.3,18.2,55.5,11.4,19.5,15.5,37.5,19.5,37.5,55.5,80.0,
         37.5,15.5,23.7,9.8,40.8,17.5,4.3,36.5,26.3,30.4,50.2,30.1,25.5,
         13.8,58.9,40.0,6.0,72.5,38.8,19.4,81.5,77.4,54.6,6.8,32.6,19.8,
         58.8,12.9,49.0)

## Create vector with batch indicator
bat = c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,
        4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
        5,6,6,6,6,6,6,6)

## Save data in a data frame and determine number of observations
Batch <- as.factor(bat)
df <- data.frame(fdef,ldef,Batch)
len <- length(Batch)

##  Plot the data
par(cex=1.25)
xax = "Lab Defect Size"
yax = "Field Defect Size"
title = "Alaska Pipeline Ultrasonic Calibration Data"
plot(ldef,fdef,xlab=xax,ylab=yax,main=title,col="blue")

## Generate conditional plot
library("lattice")
trellis.device(new = TRUE, col = FALSE)
FIG = xyplot(fdef ~ ldef | Batch, data=df,
      main = title,
      layout=c(3,2),
      col=4,
      xlab=list(xax,cex=1.1),
      ylab=list(yax,cex=1.1),
      strip=function(...)
      strip.default(...,strip.names=c(T,T)))
plot(FIG)

##  Batch analysis
x = ldef
y = fdef
xydf = data.frame(x,y,Batch)
out = by(xydf,xydf$Batch,function(x) lm(y~x,data=x))
lapply(out,summary)

#> $"1"
#>
#> Call:
#> lm(formula = y ~ x, data = x)
#>
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -8.7219 -4.9844 -0.4439  3.4162 11.6738 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  7.15730    2.97737   2.404   0.0279 *  
#> x            0.63269    0.06392   9.898 1.80e-08 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 6.526 on 17 degrees of freedom
#> Multiple R-Squared: 0.8521,     Adjusted R-squared: 0.8434 
#> F-statistic: 97.98 on 1 and 17 DF,  p-value: 1.798e-08 
#>
#>
#> $"2"
#>
#> Call:
#> lm(formula = y ~ x, data = x)
#>
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -9.09547 -5.49791  0.02057  2.75029 11.25706 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  7.51458    2.81007   2.674   0.0155 *  
#> x            0.63759    0.05828  10.941  2.2e-09 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 6.382 on 18 degrees of freedom
#> Multiple R-Squared: 0.8693,     Adjusted R-squared: 0.862 
#> F-statistic: 119.7 on 1 and 18 DF,  p-value: 2.200e-09 
#>
#>
#> $"3"
#>
#> Call:
#> lm(formula = y ~ x, data = x)
#>
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -11.370  -2.390   1.396   2.488  16.250 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  2.20247    2.82865   0.779    0.446    
#> x            0.83185    0.05901  14.096 3.63e-11 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 6.61 on 18 degrees of freedom
#> Multiple R-Squared: 0.9169,     Adjusted R-squared: 0.9123 
#> F-statistic: 198.7 on 1 and 18 DF,  p-value: 3.629e-11 
#>
#>
#> $"4"
#>
#> Call:
#> lm(formula = y ~ x, data = x)
#>
#> Residuals:
#>    Min     1Q Median     3Q    Max 
#> -9.932 -2.775 -0.374  2.889  7.930 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  3.18655    1.88338   1.692    0.108    
#> x            0.77022    0.03938  19.560 1.41e-13 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 4.381 on 18 degrees of freedom
#> Multiple R-Squared: 0.9551,     Adjusted R-squared: 0.9526 
#> F-statistic: 382.6 on 1 and 18 DF,  p-value: 1.414e-13 
#>
#>
#> $"5"
#>
#> Call:
#> lm(formula = y ~ x, data = x)
#>
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -18.5261  -2.7865   0.8096   3.4953   8.7293 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  4.86365    2.33614   2.082   0.0511 .  
#> x            0.75791    0.05724  13.241 4.83e-11 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 5.829 on 19 degrees of freedom
#> Multiple R-Squared: 0.9022,     Adjusted R-squared: 0.8971 
#> F-statistic: 175.3 on 1 and 19 DF,  p-value: 4.834e-11 
#>
#>
#> $"6"
#>
#> Call:
#> lm(formula = y ~ x, data = x)
#>
#> Residuals:
#>     101     102     103     104     105     106     107 
#>  0.7125 -0.2117 -1.9221  1.3451  1.0155  0.4188 -1.3581 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  3.22600    1.01547   3.177   0.0246 *  
#> x            0.88025    0.02621  33.584  4.4e-07 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 1.35 on 5 degrees of freedom
#> Multiple R-Squared: 0.9956,     Adjusted R-squared: 0.9947 
#> F-statistic:  1128 on 1 and 5 DF,  p-value: 4.401e-07 

## Save batch regression results 
outs = sapply(out,summary)
outc = sapply(out,coef)
fitse = t(outs[6,])
fitse = c(fitse[[1]],fitse[[2]],fitse[[3]],fitse[[4]],fitse[[5]],fitse[[6]])
r2 = t(outs[8,])
r2 = c(r2[[1]],r2[[2]],r2[[3]],r2[[4]],r2[[5]],r2[[6]])
b0 = t(outc[1,])
b1 = t(outc[2,])

##  Batch plots
par(mfrow=c(2,2))
id = c(1:length(b0))
xax2 = "Batch Number"
plot(id,r2,xlab=xax2,ylab="Correlation",ylim=c(.8,1),
     col="blue",pch=16,cex=1.25)
abline(h=mean(r2))
plot(id,b0[1,],xlab=xax2,ylab="Intercept",ylim=c(0,8),
     col="blue",pch=16,cex=1.25)
abline(h=mean(b0))
plot(id,b1[1,],xlab=xax2,ylab="Slope",ylim=c(.5,.9),
     col="blue",pch=16,cex=1.25)
abline(h=mean(b1))
plot(id,fitse,xlab=xax2,ylab="RESSD",ylim=c(0,7),
     col="blue",pch=16,cex=1.25)
abline(h=mean(fitse))
par(mfrow=c(1,1))

## Straight line regression analysis
out = lm(fdef~ldef)
summary(out)

#> Call:
#> lm(formula = fdef ~ ldef)
#>
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -16.5817  -3.8259   0.1283   3.7432  21.5174 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  4.99368    1.12566   4.436 2.26e-05 ***
#> ldef         0.73111    0.02455  29.778  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 6.081 on 105 degrees of freedom
#> Multiple R-Squared: 0.8941,     Adjusted R-squared: 0.8931 
#> F-statistic: 886.7 on 1 and 105 DF,  p-value: < 2.2e-16 

## Residual 6-plot
par(mfrow=c(3,2))
plot(ldef,fdef,xlab="Lab Defect Size",
     ylab="Field Defect Size",main="Field Defect Size vs Lab Defect Size")
abline(reg=out)
plot(ldef,out$residuals,ylab="Residuals",xlab="Lab Defect Size",
     main="Residuals vs Lab Defect Size")
plot(out$fitted.values,out$residuals,ylab="Residuals",xlab="Predicted",
     main="Residual vs Predicted")
plot(out$residuals[2:len],out$residuals[1:len-1],ylab="Residuals",
     xlab="Lag 1 Residuals",main="Lag Plot")
hist(out$residuals,ylab="Frequency",xlab="Residuals",main="Histogram")
qqnorm(out$residuals,main="Normal Probability Plot")

## Generate plot of raw data with overlaid regression function
par(mfrow=c(1,1),cex=1.25)
plot(ldef,fdef,ylab="Field Defect Size",xlab="Lab Defect Size",
     col="blue")
abline(reg=out)
title("Alaska Pipeline Ultrasonic Calibration Data",line=2)
title("With Unweighted Line",line=1)

## Plot residuals versus lab defect size
par(mfrow=c(1,1),cex=1.25)
plot(ldef,out$residuals, xlab="Lab Defect Size", ylab="Residuals",
     main="Alaska Pipeline Data Residuals - Unweighted Fit",
     cex=1.25, col="blue")
abline(h=0)

## Transformations of response variable
lnfdef = log(fdef)
sqrtfdef = sqrt(fdef)
invfdef = 1/fdef

## Plot transformed response variable
par(mfrow=c(2,2))
xax = "Lab Defect Size"
plot(ldef,fdef,xlab=xax,ylab="Field Defect Size",col="blue")
plot(ldef,sqrtfdef,xlab=xax,ylab="Sqrt(Field Defect Size)",col="blue")
plot(ldef,lnfdef,xlab=xax,ylab="ln(Field Defect Size)",col="blue")
plot(ldef,invfdef,xlab=xax,ylab="1/Field Defect Size",col="blue")
title(main="Transformations of Response Variable",outer=TRUE,line=-2)

## Transformations of predictor variable
lnldef = log(ldef)
sqrtldef = sqrt(ldef)
invldef = 1/ldef

## Plot transformed predictor variable
par(mfrow=c(2,2))
yax = "ln(Field Defect Size)"
plot(ldef,lnfdef,xlab="Lab Defect Size", ylab=yax, col="blue")
plot(sqrtldef,lnfdef,xlab="Sqrt(Lab Defect Size)", ylab=yax, col="blue")
plot(lnldef,lnfdef,xlab="ln(Lab Defect Size)", ylab=yax, col="blue")
plot(invldef,lnfdef,xlab="1/Lab Defect Size", ylab=yax, col="blue")
title(main="Transformations of Predictor Variable",outer=TRUE,line=-2)

##  Box-Cox linearity plot
for (i in (0:100)){
    alpha = -2 + 4*i/100
    if (alpha != 0){
    tx = ((ldef**alpha) - 1)/alpha
    temp = lm(lnfdef~tx)
    temps = summary(temp)
    if(i==0) {rsq = temps$r.squared
              alp = alpha}
    else {rsq = rbind(rsq,temps$r.squared)
          alp = rbind(alp,alpha)}
    }}
rcor = sqrt(rsq)
par(mfrow=c(1,1),cex=1.25)
plot(alp,rcor,type="l",xlab="Alpha",ylab="Correlation",
     main="Box-Cox Linearity Plot ln(Field) Lab",
     ylim=c(.6,1), col="blue")

## Regression for ln-ln transformed variables
outt = lm(lnfdef~lnldef)
summary(outt)

#> Call:
#> lm(formula = lnfdef ~ lnldef)
#>
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -0.33360 -0.13982  0.03105  0.12745  0.33701 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  0.28138    0.08093   3.477 0.000739 ***
#> lnldef       0.88518    0.02302  38.457  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.1683 on 105 degrees of freedom
#> Multiple R-Squared: 0.9337,     Adjusted R-squared: 0.9331 
#> F-statistic:  1479 on 1 and 105 DF,  p-value: < 2.2e-16 

## Plot data with overlaid regression function
par(mfrow=c(1,1),cex=1.25)
plot(lnldef,lnfdef,xlab="ln(Lab Defect Size)",ylab="ln(Field Defect Size)",
     main="Transformed Alaska Pipeline Data with Fit",col="blue")
abline(reg=outt)

## Residual 6-plot
par(mfrow=c(3,2))
plot(lnldef,lnfdef,xlab="ln(Lab Defect Size)",ylab="ln(Field Defect Size)",
     main="ln(Field Defect Size vs ln(Lab Defect Size)")
abline(reg=outt)
plot(lnfdef,outt$residuals, xlab="ln(Lab Defect Size)",ylab="Residuals",
     main="Residual vs ln(Lab Defect Size)")
plot(outt$residuals,outt$fitted.values,ylab="Residuals",xlab="Predicted",
     main="Residual vs Predicted")
plot(outt$residuals[2:len],outt$residuals[1:len-1],ylab="Residuals",
     xlab="Lag 1 Residuals",main="Lag Plot")
hist(outt$residuals,ylab="Frequency",xlab="Residuals",main="Histogram")
qqnorm(outt$residuals,main="Normal Probability Plot")

## Plot residuals versus ln(lab defect size)
par(mfrow=c(1,1),cex=1.25)
plot(lnldef,outt$residuals, xlab="ln(Lab Defect Size)",
     ylab="Residuals", main="Residuals from Fit to Transformed Data",
     cex=1.25, col="blue")
abline(h=0)

## Determine replicate groups
df = data.frame(ldef,fdef)
df = df[order(ldef),]
id = rep(1:27,each=4)
id = id[1:length(ldef)]
dfid = data.frame(id,df)

m = by(dfid$fdef,id,mean)
s2 = by(dfid$fdef,id,var)
mfdef = as.vector(m)
vfdef = as.vector(s2)
lnmfdef = log(mfdef)
lnvfdef = log(vfdef)

## Fit power function model
out2 = lm(lnvfdef~lnmfdef)
summary(out2)

#> Call:
#> lm(formula = lnvfdef ~ lnmfdef)
#>
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -2.0038 -0.5934  0.1245  0.5605  1.7062 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  -3.1573     0.8696  -3.631  0.00127 ** 
#> lnmfdef       1.7087     0.2552   6.694 5.14e-07 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.8391 on 25 degrees of freedom
#> Multiple R-Squared: 0.6419,     Adjusted R-squared: 0.6276 
#> F-statistic: 44.82 on 1 and 25 DF,  p-value: 5.143e-07 

## Plot power function model with power function
par(mfrow=c(1,1),cex=1.25)
plot(lnmfdef,lnvfdef,xlim=c(1,5),ylim=c(-1,6),
     ylab="ln(Replicate Variances)", xlab="ln(Replicate Means)",
     main="Fit for Estimating Weights", cex=1.25, col="blue")
abline(reg=out2)

## Plot residuals from power function model
par(mfrow=c(1,1),cex=1.25)
plot(lnmfdef,out2$residuals, main="Residuals from Weight Estimation Fit",
     ylab="Residuals", xlab="ln(Replicate Means)",ylim=c(-2,2),
     xlim=c(1,5), cex=1.25, col="blue")
abline(h=0)

## Weighted regression analysis
w = 1/(ldef**1.5)
outw = lm(fdef~ldef,weight=w)
summary(outw)
wresid = weighted.residuals(outw)

#> Call:
#> lm(formula = fdef ~ ldef, weights = w)
#>
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -0.75742 -0.30420  0.07279  0.25865  0.78715 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  2.35234    0.54312   4.331  3.4e-05 ***
#> ldef         0.80636    0.02265  35.595  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.3646 on 105 degrees of freedom
#> Multiple R-Squared: 0.9235,     Adjusted R-squared: 0.9227 
#> F-statistic:  1267 on 1 and 105 DF,  p-value: < 2.2e-16 

## Plot data with overlaid weighted regression function
par(mfrow=c(1,1),cex=1.25)
plot(ldef,fdef,ylab="Field Defect Size", xlab="Lab Defect Size",
     col="blue")
abline(reg=outw)
title("Alaska Pipeline Data with Weighted Fit",line=2)
title("Weights=1/(Lab Defect Size)**1.5",line=1)

## Residual 6-plot
par(mfrow=c(3,2))
plot(ldef,fdef,xlab="Lab Defect Size",
     ylab="Field Defect Size",main="Field Defect Size vs Lab Defect Size")
abline(reg=outw)
plot(ldef,wresid,ylab="Residuals",xlab="Lab Defect Size",
     main="Residuals vs Lab Defect Size")
plot(outw$fitted.values,wresid,ylab="Residuals",xlab="Predicted",
     main="Residual vs Predicted")
plot(wresid[2:len],wresid[1:len-1],ylab="Residuals",
     xlab="Lag 1 Residuals",main="Lag Plot")
hist(wresid,ylab="Frequency",xlab="Residuals",main="Histogram")
qqnorm(wresid,main="Normal Probability Plot")

## Plot weighted residuals versus lab defect size
par(mfrow=c(1,1),cex=1.25)
plot(ldef,wresid,ylab="Residuals",xlab="Lab Defect Size",
     main="Residuals from Weighted Fit")
abline(h=0)

##  Generate plot to compare three fits
xval = seq(min(ldef),max(ldef))
yu = predict.lm(out,data.frame(ldef=xval))
yt = exp(outt$coef[1]+outt$coef[2]*log(xval))
yw = predict.lm(outw,data.frame(ldef=xval))

par(mfrow=c(1,1),cex=1.25)
plot(ldef,fdef,ylab="Field Defect Size", xlab="Lab Defect Size",
     xlim=c(0,90),ylim=c(0,90), cex=.85)
lines(x=xval,y=yu,lty=1, col="red")
lines(x=xval,y=yt,lty=2, col="black")
lines(x=xval,y=yw,lty=3, col="blue")
legend(85,legend=c("Unweighted Fit","Transformed Fit","Weighted Fit"),
       lty=c(1,2,3), col=c("red","black","blue"))
title("Data with Unweighted Line, WLS Fit,",line=2)
title("and Fit Using Transformed Variables",line=1)

#R commands and output:

## Ultrasonic reference block case study.

## Create vector with dependent variable, ultrasonic response
resp = c( 92.9000,78.7000,64.2000,64.9000,57.1000,43.3000,31.1000,23.6000,
          31.0500,23.7750,17.7375,13.8000,11.5875,9.4125,7.7250,7.3500,
          8.0250,90.6000,76.9000,71.6000,63.6000,54.0000,39.2000,29.3000,
          21.4000,29.1750,22.1250,17.5125,14.2500,9.4500,9.1500,7.9125,
          8.4750,6.1125,80.0000,79.0000,63.8000,57.2000,53.2000,42.5000,
          26.8000,20.4000,26.8500,21.0000,16.4625,12.5250,10.5375,8.5875,
          7.1250,6.1125,5.9625,74.1000,67.3000,60.8000,55.5000,50.3000,
          41.0000,29.4000,20.4000,29.3625,21.1500,16.7625,13.2000,10.8750,
          8.1750,7.3500,5.9625,5.6250,81.5000,62.4000,32.5000,12.4100,
          13.1200,15.5600,5.6300,78.0000,59.9000,33.2000,13.8400,12.7500,
          14.6200,3.9400,76.8000,61.0000,32.9000,13.8700,11.8100,13.3100,
          5.4400,78.0000,63.5000,33.8000,12.5600,5.6300,12.7500,13.1200,
          5.4400,76.8000,60.0000,47.8000,32.0000,22.2000,22.5700,18.8200,
          13.9500,11.2500,9.0000,6.6700,75.8000,62.0000,48.8000,35.2000,  
          20.0000,20.3200,19.3100,12.7500,10.4200,7.3100,7.4200,70.5000,
          59.5000,48.5000,35.8000,21.0000,21.6700,21.0000,15.6400,8.1700,
          8.5500,10.1200,78.0000,66.0000,62.0000,58.0000,47.7000,37.8000,
          20.2000,21.0700,13.8700,9.6700,7.7600,5.4400,4.8700,4.0100,3.7500,
          24.1900,25.7600,18.0700,11.8100,12.0700,16.1200,70.8000,54.7000,
          48.0000,39.8000,29.8000,23.7000,29.6200,23.8100,17.7000,11.5500,
          12.0700,8.7400,80.7000,61.3000,47.5000,29.0000,24.0000,17.7000,
          24.5600,18.6700,16.2400,8.7400,7.8700,8.5100,66.7000,59.2000,
          40.8000,30.7000,25.7000,16.3000,25.9900,16.9500,13.3500,8.6200,
          7.2000,6.6400,13.6900,81.0000,64.5000,35.5000,13.3100,4.8700,
          12.9400,5.0600,15.1900,14.6200,15.6400,25.5000,25.9500,81.7000,
          61.6000,29.8000,29.8100,17.1700,10.3900,28.4000,28.6900,81.3000,
          60.9000,16.6500,10.0500,28.9000,28.9500)

## Create vector with independent variable, metal distance
dist = c(0.500,0.625,0.750,0.875,1.000,1.250,1.750,2.250,1.750,2.250,2.750,
         3.250,3.750,4.250,4.750,5.250,5.750,0.500,0.625,0.750,0.875,1.000,
         1.250,1.750,2.250,1.750,2.250,2.750,3.250,3.750,4.250,4.750,5.250,
         5.750,0.500,0.625,0.750,0.875,1.000,1.250,1.750,2.250,1.750,2.250,
         2.750,3.250,3.750,4.250,4.750,5.250,5.750,0.500,0.625,0.750,0.875,
         1.000,1.250,1.750,2.250,1.750,2.250,2.750,3.250,3.750,4.250,4.750,
         5.250,5.750,0.500,0.750,1.500,3.000,3.000,3.000,6.000,0.500,0.750,
         1.500,3.000,3.000,3.000,6.000,0.500,0.750,1.500,3.000,3.000,3.000,
         6.000,0.500,0.750,1.500,3.000,6.000,3.000,3.000,6.000,0.500,0.750,
         1.000,1.500,2.000,2.000,2.500,3.000,4.000,5.000,6.000,0.500,0.750,
         1.000,1.500,2.000,2.000,2.500,3.000,4.000,5.000,6.000,0.500,0.750,
         1.000,1.500,2.000,2.000,2.500,3.000,4.000,5.000,6.000,0.500,0.625,
         0.750,0.875,1.000,1.250,2.250,2.250,2.750,3.250,3.750,4.250,4.750,
         5.250,5.750,3.000,3.000,3.000,3.000,3.000,3.000,0.500,0.750,1.000,
         1.500,2.000,2.500,2.000,2.500,3.000,4.000,5.000,6.000,0.500,0.750,
         1.000,1.500,2.000,2.500,2.000,2.500,3.000,4.000,5.000,6.000,0.500,
         0.750,1.000,1.500,2.000,2.500,2.000,2.500,3.000,4.000,5.000,6.000,
         3.000,0.500,0.750,1.500,3.000,6.000,3.000,6.000,3.000,3.000,3.000, 
         1.750,1.750,0.500,0.750,1.750,1.750,2.750,3.750,1.750,1.750,0.500,
         0.750,2.750,3.750,1.750,1.750)

## Save data in a data frame and determine the number of observations
df = data.frame(resp,dist)
len = length(resp)

##  Plot the data
par(mfrow=c(1,1),cex=1.25)
xax = "Metal Distance"
yax = "Ultrasonic Response"
ttl = "Ultrasonic Reference Block Data"
plot(dist,resp, xlab=xax, ylab=yax, main=ttl,col="blue")

## Fit initial model
out = nls(resp ~ exp(-b1*dist)/(b2 + b3*dist),
           start=list(b1=.1,b2=.1,b3=.1))
outs = summary(out)
outs
upred = resp - outs$resid
udfout = data.frame(upred,dist)
udfout = udfout[order(dist),]

#> Formula: resp ~ exp(-b1 * dist)/(b2 + b3 * dist)
#>
#> Parameters:
#>     Estimate Std. Error t value Pr(#>|t|)    
#> b1 0.1902787  0.0219386   8.673 1.13e-15 ***
#> b2 0.0061314  0.0003450  17.772  < 2e-16 ***
#> b3 0.0105309  0.0007928  13.283  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 3.362 on 211 degrees of freedom

## Plot data and fitted curve
par(mfrow=c(1,1),cex=1.25)
plot(dist,resp,xlab=xax,ylab=yax,col="blue")
lines(udfout$dist,udfout$upred)
title("Ultrasonic Reference Block Data",line=2)
title("With Unweighted Nonlinear Fit",line=1)

## Residual 6-plot
par(mfrow=c(3,2))
plot(dist,resp,xlab=xax, ylab=yax, main=ttl)
lines(udfout$dist,udfout$pred)
plot(dist,outs$resid, ylab="Residuals", xlab="Distance",
     main="Residuals vs Distance")
plot(upred,outs$resid, ylab="Residuals", xlab="Predicted",
     main="Residual vs Predicted")
plot(outs$resid[2:len],outs$resid[1:len-1], ylab="Residuals",
     xlab="Lag 1 Residuals", main="Lag Plot")
hist(outs$resid, ylab="Frequency", xlab="Residuals",main="Histogram")
qqnorm(outs$resid, main="Normal Probability Plot")

## Isolate residual plot
par(mfrow=c(1,1),cex=1.25)
plot(dist,outs$resid, ylab="Residuals", xlab="Metal Distance",
     col="blue")
abline(h=0)
title("Ultrasonic Reference Block Data Residuals",line=2)
title("Unweighted Fit",line=1) 

## specify axis labels and plot title
xax = "Metal Distance"
yax = "Ultrasonic Response"
ttl = "Ultrasonic Reference Block Data"

## Transformations of response variable
lnresp = log(resp)
sqrtresp = sqrt(resp)
invresp = 1/resp

## Plot transformed data
par(mfrow=c(2,2))
xax = "Metal Distance"
plot(dist,resp,xlab=xax,ylab="Ultrasonic Response",col="blue")
plot(dist,sqrtresp,xlab=xax,ylab="Sqrt(Ultrasonic Response)",col="blue")
plot(dist,lnresp,xlab=xax,ylab="ln(Ultrasonic Response)",col="blue")
plot(dist,invresp,xlab=xax,ylab="1/Ultrasonic Response",col="blue")
title(main="Transformations of Response Variable",outer=TRUE,line=-2)

## Transformations of predictor variable
lndist = log(dist)
sqrtdist = sqrt(dist)
invdist = 1/dist

## Plot transformed data
par(mfrow=c(2,2))
yax <- "Sqrt(Ultrasonic Response)"
plot(dist,sqrtresp,xlab="Metal Distance", ylab=yax, col="blue")
plot(sqrtdist,sqrtresp,xlab="Sqrt(Metal Distance)", ylab=yax, col="blue")
plot(lndist,sqrtresp,xlab="ln(Metal Distance)", ylab=yax, col="blue")
plot(invdist,sqrtresp,xlab="1/(Metal Distance)", ylab=yax, col="blue")
title(main="Transformations of Predictor Variable",outer=TRUE,line=-2)

##  Fit model with sqrt(Ultrasonic Response)
out = nls(sqrtresp ~ exp(-b1*dist)/(b2 + b3*dist),
          start=list(b1=.1,b2=.1,b3=.1))
outs = summary(out)
outs

#> Formula: sqrtresp ~ exp(-b1 * dist)/(b2 + b3 * dist)
#>
#> Parameters:
#>     Estimate Std. Error t value Pr(#>|t|)    
#> b1 -0.015428   0.008611  -1.792   0.0746 .  
#> b2  0.080672   0.001506  53.577   <2e-16 ***
#> b3  0.063857   0.002880  22.173   <2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.2972 on 211 degrees of freedom

## Save fit information for plotting
pred = sqrtresp - outs$resid
dfout = data.frame(pred,dist)
dfout = dfout[order(dist),]

## Plot data and regression function
par(mfrow=c(1,1),cex=1.25)
plot(dist,sqrtresp,xlab=xax,ylab=yax,
     main="Transformed Data with Fit",col="blue")
lines(dfout$dist,dfout$pred)

## Residual 6-plot
par(mfrow=c(3,2))
plot(dist,sqrtresp,xlab=xax, ylab="Sqrt(Ultrasonic Response)", 
     main=ttl)
lines(dfout$dist,dfout$pred)
plot(dist,outs$resid, ylab="Residuals", xlab="Metal Distance",
     main="Residuals vs Metal Distance")
plot(pred,outs$resid, ylab="Residuals", xlab="Predicted",
     main="Residual vs Predicted")
plot(outs$resid[2:len],outs$resid[1:len-1], ylab="Residuals",
     xlab="Lag 1 Residuals", main="Lag Plot")
hist(outs$resid, ylab="Frequency", xlab="Residuals", main="Histogram")
qqnorm(outs$resid, main="Normal Probability Plot")

##  Isolate residual plot
par(mfrow=c(1,1),cex=1.25)
plot(dist,outs$resid, ylab="Residuals", xlab="Metal Distance",
     main="Residuals From Fit to Transformed Data", col="blue")
abline(h=0)

##  Determine Weights
dfs = df[order(dist),]
d = by(dfs$dist,dfs$dist,mean)
s2 = by(dfs$resp,dfs$dist,var)
md = as.vector(d)
vresp = as.vector(s2)
lnmd = log(md)
lnvresp = log(vresp)
out2 = lm(lnvresp~lnmd)
summary(out2)

#> Call:
#> lm(formula = lnvresp ~ lnmd)
#>
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -1.1471 -0.4365  0.0985  0.4271  1.0269 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)   2.5369     0.1919   13.22 2.42e-11 ***
#> lnmd         -1.1128     0.1741   -6.39 3.11e-06 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.6099 on 20 degrees of freedom
#> Multiple R-Squared: 0.6712,     Adjusted R-squared: 0.6548 
#> F-statistic: 40.83 on 1 and 20 DF,  p-value: 3.106e-06 

##  Plot data and fitted line
par(mfrow=c(1,1),cex=1.25)
plot(lnmd,lnvresp,xlim=c(-1,2),ylim=c(0,4),ylab="ln(Replicate Variances)",
     xlab="ln(Metal Distance)", main="Fit for Estimating Weights",
     cex=1.25,col="blue")
abline(reg=out2)

## Plot residuals
par(mfrow=c(1,1),cex=1.25)
plot(lnmd,out2$residuals, main="Residuals from Weight Estimation Fit",
     ylab="Residuals", xlab="ln(Metal Distance)",ylim=c(-2,2),
     xlim=c(-1,2), col="blue")
abline(h=0)

## Weighted regression analysis
w = 1/(dist**(-1))
outw = nls(~ sqrt(w)*(resp - exp(-b1*dist)/(b2 + b3*dist)),
           start=list(b1=.1,b2=.1,b3=.1))
outs = summary(outw)
outs

#> Formula: 0 ~ sqrt(w) * (resp - exp(-b1 * dist)/(b2 + b3 * dist))
#>
#> Parameters:
#>     Estimate Std. Error t value Pr(#>|t|)    
#> b1 0.1469999  0.0150471   9.769   <2e-16 ***
#> b2 0.0052801  0.0004021  13.131   <2e-16 ***
#> b3 0.0123875  0.0007362  16.826   <2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 4.111 on 211 degrees of freedom

## Save fit information for plotting
wpred = exp(-outs$parameters[1,1]*dist)/(outs$parameters[2,1] + 
        outs$parameters[3,1]*dist)
resid = resp - wpred
wresid = sqrt(w)*(resp-wpred)
wdfout = data.frame(wpred,dist)
wdfout = wdfout[order(dist),]

## Plot data with overlaid fitted curve
par(mfrow=c(1,1),cex=1.25)
plot(dist,resp,xlab="Metal Distance", ylab="Ultrasonic Response",
     col="blue")
lines(wdfout$dist,wdfout$wpred)
title("Ultrasonic Data with Weighted Fit",line=2)
title("Weights=1/(Metal Distance)**(-1)",line=1)

## Residual 6-plot
par(mfrow=c(3,2))
plot(dist,resp,xlab="Metal Distance", ylab="Ultrasonic Response",
     main="Ultrasonic Response vs Metal Distance")
lines(wdfout$dist,wdfout$wpred)
plot(dist,wresid,ylab="Residuals",xlab="Metal Distance",
     main="Residuals vs Metal Distance")
plot(wpred,wresid,ylab="Residuals",xlab="Predicted",
     main="Residual vs Predicted")
plot(wresid[2:len],wresid[1:len-1],ylab="Residuals",
     xlab="Lag 1 Residuals",main="Lag Plot")
hist(wresid,ylab="Frequency",xlab="Residuals",main="Histogram")
qqnorm(wresid,main="Normal Probability Plot")

## Isolate residual plot
par(mfrow=c(1,1),cex=1.25)
plot(dist,wresid,ylab="Residuals",xlab="Metal Distance",
     main="Residuals from Weighted Fit", col="blue")
abline(h=0)

## Compare three models
## Fit initial model
out = nls(resp ~ exp(-b1*dist)/(b2 + b3*dist),
          start=list(b1=.1,b2=.1,b3=.1))
outi = summary(out)
uressd = outi$sigma
upred = resp - outi$resid
udfout = data.frame(upred,dist)
udfout = udfout[order(dist),]

## Fit model with sqrt(Ultrasonic Response)
sqrtresp = sqrt(resp)
out = nls(sqrtresp ~ exp(-b1*dist)/(b2 + b3*dist),
          start=list(b1=.1,b2=.1,b3=.1))
outt = summary(out)
pred = sqrtresp - outt$resid
dfout = data.frame(pred,dist)
dfout = dfout[order(dist),]
tpred = pred**2
tresid = resp - tpred
tressd = sqrt(sum(tresid**2)/outt$df[2])

## Weighted regression analysis
w = 1/(dist**(-1))
out = nls(~ sqrt(w)*(resp - exp(-b1*dist)/(b2 + b3*dist)),
          start=list(b1=.1,b2=.1,b3=.1))
outw = summary(out)
wpred = exp(-outw$parameters[1,1]*dist)/(outw$parameters[2,1] + 
        outw$parameters[3,1]*dist)
resid = resp - wpred
wresid = sqrt(w)*(resp-wpred)
wdfout = data.frame(wpred,dist)
wdfout = wdfout[order(dist),]
wressd = sqrt(sum(resid**2)/outw$df[2])

## Plot to compare fits
par(mfrow=c(1,1),cex=1.25)
plot(dist,resp,xlab="Metal Distance", ylab="Ultrasonic Response")
lines(udfout$dist,udfout$upred, lty=1, col="red")
lines(dfout$dist,dfout$pred**2, lty=2, col="black")
lines(wdfout$dist, wdfout$wpred, lty=3,col="blue")
legend(x=3,y=80,
       legend=c("Unweighted Fit","Transformed Fit","Weighted Fit"),
       lty=c(1,2,3), col=c("red","black","blue"))
title("Data with Unweighted Line, WLS Fit,",line=2)
title("and Fit Using Transformed Variables",line=1)

##  Compare RESSD from fits
## RESSD from original fit
uressd

#> [1] 3.361672

## RESSD from fit using transformed response
tressd

#> [1] 3.323509

## RESSD from weighted fit
wressd

#> [1] 3.40894


#R commands and output:

## Thermal expansion of copper case study

## Create vector with dependent variable, coefficient of thermal expansion
tec = c(0.591,1.547,2.902,2.894,4.703,6.307,7.030,7.898,9.470,9.484,10.072,
      10.163,11.615,12.005,12.478,12.982,12.970,13.926,14.452,14.404,
      15.190,15.550,15.528,15.499,16.131,16.438,16.387,16.549,16.872,
      16.830,16.926,16.907,16.966,17.060,17.122,17.311,17.355,17.668,
      17.767,17.803,17.765,17.768,17.736,17.858,17.877,17.912,18.046,
      18.085,18.291,18.357,18.426,18.584,18.610,18.870,18.795,19.111,
      0.367,0.796,0.892,1.903,2.150,3.697,5.870,6.421,7.422,9.944,11.023,
      11.870,12.786,14.067,13.974,14.462,14.464,15.381,15.483,15.590,
      16.075,16.347,16.181,16.915,17.003,16.978,17.756,17.808,17.868,
      18.481,18.486,19.090,16.062,16.337,16.345,16.388,17.159,17.116,
      17.164,17.123,17.979,17.974,18.007,17.993,18.523,18.669,18.617,
      19.371,19.330,0.080,0.248,1.089,1.418,2.278,3.624,4.574,5.556,
      7.267,7.695,9.136,9.959,9.957,11.600,13.138,13.564,13.871,13.994,
      14.947,15.473,15.379,15.455,15.908,16.114,17.071,17.135,17.282,
      17.368,17.483,17.764,18.185,18.271,18.236,18.237,18.523,18.627,
      18.665,19.086,0.214,0.943,1.429,2.241,2.951,3.782,4.757,5.602,
      7.169,8.920,10.055,12.035,12.861,13.436,14.167,14.755,15.168,
      15.651,15.746,16.216,16.445,16.965,17.121,17.206,17.250,17.339,
      17.793,18.123,18.490,18.566,18.645,18.706,18.924,19.100,0.375,
      0.471,1.504,2.204,2.813,4.765,9.835,10.040,11.946,12.596,13.303,
      13.922,14.440,14.951,15.627,15.639,15.814,16.315,16.334,16.430,
      16.423,17.024,17.009,17.165,17.134,17.349,17.576,17.848,18.090,
      18.276,18.404,18.519,19.133,19.074,19.239,19.280,19.101,19.398,
      19.252,19.890,20.007,19.929,19.268,19.324,20.049,20.107,20.062,
      20.065,19.286,19.972,20.088,20.743,20.830,20.935,21.035,20.930,
      21.074,21.085,20.935)

## Create vector with independent variable, temperature (K)
temp = c(24.41,34.82,44.09,45.07,54.98,65.51,70.53,75.70,89.57,91.14,96.40,
      97.19,114.26,120.25,127.08,133.55,133.61,158.67,172.74,171.31,
      202.14,220.55,221.05,221.39,250.99,268.99,271.80,271.97,321.31,
      321.69,330.14,333.03,333.47,340.77,345.65,373.11,373.79,411.82,
      419.51,421.59,422.02,422.47,422.61,441.75,447.41,448.70,472.89,
      476.69,522.47,522.62,524.43,546.75,549.53,575.29,576.00,625.55,
      20.15,28.78,29.57,37.41,39.12,50.24,61.38,66.25,73.42,95.52,
      107.32,122.04,134.03,163.19,163.48,175.70,179.86,211.27,217.78,
      219.14,262.52,268.01,268.62,336.25,337.23,339.33,427.38,428.58,
      432.68,528.99,531.08,628.34,253.24,273.13,273.66,282.10,346.62,
      347.19,348.78,351.18,450.10,450.35,451.92,455.56,552.22,553.56,
      555.74,652.59,656.20,14.13,20.41,31.30,33.84,39.70,48.83,54.50,
      60.41,72.77,75.25,86.84,94.88,96.40,117.37,139.08,147.73,158.63,
      161.84,192.11,206.76,209.07,213.32,226.44,237.12,330.90,358.72,
      370.77,372.72,396.24,416.59,484.02,495.47,514.78,515.65,519.47,
      544.47,560.11,620.77,18.97,28.93,33.91,40.03,44.66,49.87,55.16,
      60.90,72.08,85.15,97.06,119.63,133.27,143.84,161.91,180.67,
      198.44,226.86,229.65,258.27,273.77,339.15,350.13,362.75,371.03,
      393.32,448.53,473.78,511.12,524.70,548.75,551.64,574.02,623.86,
      21.46,24.33,33.43,39.22,44.18,55.02,94.33,96.44,118.82,128.48,
      141.94,156.92,171.65,190.00,223.26,223.88,231.50,265.05,269.44,
      271.78,273.46,334.61,339.79,349.52,358.18,377.98,394.77,429.66,
      468.22,487.27,519.54,523.03,612.99,638.59,641.36,622.05,631.50,
      663.97,646.90,748.29,749.21,750.14,647.04,646.89,746.90,748.43,
      747.35,749.27,647.61,747.78,750.51,851.37,845.97,847.54,849.93,
      851.61,849.75,850.98,848.23)

## Determine number of observations
len = length(tec)

## Save labels for plots
xax = "Temperature (K)"
yax = "Coefficient of Thermal Expansion"
ttl = "Thermal Expansion of Copper Data"
ttl2 = "Q/Q Rational Function Model"

## Plot the data
par(mfrow=c(1,1),cex=1.25)
plot(temp,tec,xlab=xax,ylab=yax,main=ttl,col="blue")

## Starting values for Q/Q model
x = c(10,50,120,200,800)
y = c(0,5,12,15,20)
x2 = x*x
xy = -x*y
x2y = -(x*x*y)
sout = lm(y~x+x2+xy+x2y)
stc = sout$coef
stc

#>   (Intercept)             x            x2            xy           x2y 
#> -3.0054502985  0.3688294835 -0.0068284454 -0.0112341033 -0.0003061251 

## Fit Q/Q model
out = nls(tec ~ (a0 + a1*temp + a2*temp**2)/(1 + b1*temp + b2*temp**2),
    start=list(a0=stc[1],a1=stc[2],a2=stc[3],b1=stc[4],b2=stc[5]))
outs = summary(out)
outs

#> Formula: tec ~ (a0 + a1 * temp + a2 * temp^2)/(1 + b1 * temp + b2 * temp^2)
#>
#> Parameters:
#>      Estimate Std. Error t value Pr(#>|t|)    
#> a0 -8.028e+00  3.988e-01  -20.13   <2e-16 ***
#> a1  5.083e-01  1.930e-02   26.33   <2e-16 ***
#> a2 -7.307e-03  2.463e-04  -29.67   <2e-16 ***
#> b1 -7.040e-03  5.235e-04  -13.45   <2e-16 ***
#> b2 -3.288e-04  1.242e-05  -26.47   <2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.5501 on 231 degrees of freedom

## Save fit information for plotting
pred = tec - outs$resid
dfout = data.frame(pred,temp)
dfout = dfout[order(temp),]

## Plot data and predicted curve
par(mfrow=c(1,1),cex=1.25)
plot(temp,tec,xlab=xax,ylab=yax,col="blue")
lines(dfout$temp,dfout$pred)
title(ttl,line=2)
title(ttl2,line=1)

## Residual 6-plot
par(mfrow=c(3,2))
plot(temp,tec,xlab=xax, ylab=yax, main=ttl)
lines(dfout$temp,dfout$pred)
plot(temp,outs$resid, ylab="Residuals", xlab="Temperature (K)",
     main="Residuals vs Temperature")
plot(pred,outs$resid, ylab="Residuals", xlab="Predicted",
     main="Residual vs Predicted")
plot(outs$resid[2:len],outs$resid[1:len-1], ylab="Residuals",
     xlab="Lag 1 Residuals", main="Lag Plot")
hist(outs$resid, ylab="Frequency", xlab="Residuals", 
     main="Histogram")
qqnorm(outs$resid, main="Normal Probability Plot")

## Isolate residual plot
par(mfrow=c(1,1),cex=1.25)
plot(temp,outs$resid, ylab="Residuals", xlab="Temperature (K)",
     main="Residuals from Q/Q Fit", col="blue")
abline(h=0)

## Generate starting values for C/C model
x = c(10,30,40,50,120,200,800)
y = c(0,2,3,5,12,15,20)
x2 = x*x
x3 = x*x*x
xy = -x*y
x2y = -(x*x*y)
x3y = -(x*x*x*y)
sout = lm(y~x+x2+x3+xy+x2y+x3y)
stc = sout$coef
stc

#>   (Intercept)             x            x2            x3            xy 
#> -2.323648e+00  3.530298e-01 -1.383334e-02  1.766845e-04 -3.395949e-02 
#>           x2y           x3y 
#>  1.100686e-04  7.910518e-06 

## Fit C/C model
out = nls(tec ~ (a0 + a1*temp + a2*temp**2 + a3*temp**3)/
          (1 + b1*temp + b2*temp**2 + b3*temp**3),
      start=list(a0=stc[1],a1=stc[2],a2=stc[3],a3=stc[4],
               b1=stc[5],b2=stc[6],b3=stc[7]))
outs = summary(out)
outs

#> Formula: tec ~ (a0 + a1 * temp + a2 * temp^2 + a3 * temp^3)/(1 + b1 * 
#>     temp + b2 * temp^2 + b3 * temp^3)
#>
#> Parameters:
#>      Estimate Std. Error t value Pr(#>|t|)    
#> a0  1.078e+00  1.707e-01   6.313 1.40e-09 ***
#> a1 -1.227e-01  1.200e-02 -10.224  < 2e-16 ***
#> a2  4.086e-03  2.251e-04  18.155  < 2e-16 ***
#> a3 -1.426e-06  2.758e-07  -5.172 5.06e-07 ***
#> b1 -5.761e-03  2.471e-04 -23.312  < 2e-16 ***
#> b2  2.405e-04  1.045e-05  23.019  < 2e-16 ***
#> b3 -1.231e-07  1.303e-08  -9.453  < 2e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
#>
#> Residual standard error: 0.0818 on 229 degrees of freedom

## Save fit information for plotting
pred = tec - outs$resid
dfout = data.frame(pred,temp)
dfout = dfout[order(temp),]

## Plot data and predicted curve
par(mfrow=c(1,1),cex=1.25)
plot(temp,tec,xlab=xax,ylab=yax,col="blue")
lines(dfout$temp,dfout$pred)
title(ttl,line=2)
title(ttl2,line=1)

## Residual 6-plot
par(mfrow=c(3,2))
plot(temp,tec,xlab=xax, ylab=yax, main=ttl)
lines(dfout$temp,dfout$pred)
plot(temp,outs$resid, ylab="Residuals", xlab="Temperature (K)",
     main="Residuals vs Temperature")
plot(pred,outs$resid, ylab="Residuals", xlab="Predicted",
     main="Residual vs Predicted")
plot(outs$resid[2:len],outs$resid[1:len-1], ylab="Residuals",
     xlab="Lag 1 Residuals", main="Lag Plot")
hist(outs$resid, ylab="Frequency", xlab="Residuals", 
     main="Histogram")
qqnorm(outs$resid, main="Normal Probability Plot")

## Isolate residual plot
par(mfrow=c(1,1),cex=1.25)
plot(temp,outs$resid, ylab="Residuals", xlab="Temperature (K)",
     main="Residuals from C/C Fit",col="blue")
abline(h=0)








#R commands and output:

## Read data and save relevant variables.
m = matrix(scan("../res/ceramic.dat",skip=1),ncol=7,byrow=T)
strength = m[,6]
order = m[,7]

## Save variables as factors.
speed = as.factor(m[,1])
rate = as.factor(m[,2])
grit = as.factor(m[,3])
direction = as.factor(m[,4])
batch = as.factor(m[,5])

## Save numeric variables and interactions.
s = m[,1]
r = m[,2]
g = m[,3]
d = m[,4]
b = m[,5]
db = d*b
gd = g*d
gb = g*b
rg = r*g
rd = r*d
rb = r*b
sr = s*r
sg = s*g
ds = s*d
sb = s*b

df = data.frame(speed,rate,grit,direction,batch,strength,order,
     s,r,g,d,b,db,gd,gb,rg,rd,rb,sr,sg,ds,sb)
df[,1:7]

###>    speed rate grit direction batch strength order
###> 1     -1   -1   -1        -1    -1   680.45    17
###> 2      1   -1   -1        -1    -1   722.48    30
###> 3     -1    1   -1        -1    -1   702.14    14
###> 4      1    1   -1        -1    -1   666.93     8
###> 5     -1   -1    1        -1    -1   703.67    32
###> 6      1   -1    1        -1    -1   642.14    20
###> 7     -1    1    1        -1    -1   692.98    26
###> 8      1    1    1        -1    -1   669.26    24
###> 9     -1   -1   -1         1    -1   491.58    10
###> 10     1   -1   -1         1    -1   475.52    16
###> 11    -1    1   -1         1    -1   478.76    27
###> 12     1    1   -1         1    -1   568.23    18
###> 13    -1   -1    1         1    -1   444.72     3
###> 14     1   -1    1         1    -1   410.37    19
###> 15    -1    1    1         1    -1   428.51    31
###> 16     1    1    1         1    -1   491.47    15
###> 17    -1   -1   -1        -1     1   607.34    12
###> 18     1   -1   -1        -1     1   620.80     1
###> 19    -1    1   -1        -1     1   610.55     4
###> 20     1    1   -1        -1     1   638.04    23
###> 21    -1   -1    1        -1     1   585.19     2
###> 22     1   -1    1        -1     1   586.17    28
###> 23    -1    1    1        -1     1   601.67    11
###> 24     1    1    1        -1     1   608.31     9
###> 25    -1   -1   -1         1     1   442.90    25
###> 26     1   -1   -1         1     1   434.41    21
###> 27    -1    1   -1         1     1   417.66     6
###> 28     1    1   -1         1     1   510.84     7
###> 29    -1   -1    1         1     1   392.11     5
###> 30     1   -1    1         1     1   343.22    13
###> 31    -1    1    1         1     1   385.52    22
###> 32     1    1    1         1     1   446.73    29


## Generate four plots.
par(bg=rgb(1,1,0.8), mfrow=c(2,2))
qqnorm(strength)
qqline(strength, col = 2)
boxplot(strength, horizontal=TRUE, main="Box Plot", xlab="Strength")
hist(strength, main="Histogram", xlab="Strength")
plot(order, strength, xlab="Actual Run Order", ylab="Strength",
     main="Run Order Plot")
par(mfrow=c(1,1))


par(bg=rgb(1,1,0.8),mfrow=c(2,3))
boxplot(strength~speed, data=df, main="Strength by Table Speed",
        xlab="Table Speed",ylab="Strength")

boxplot(strength~rate, data=df, main="Strength by Feed Rate",
        xlab="Feed Rate",ylab="Strength")

boxplot(strength~grit, data=df, main="Strength by Wheel Grit",
        xlab="Wheel Grit",ylab="Strength")

boxplot(strength~direction, data=df, main="Strength by Direction",
        xlab="Direction",ylab="Strength")

boxplot(strength~batch, data=df, main="Strength by Batch",
        xlab="Batch",ylab="Strength")
par(mfrow=c(1,1))


## Fit a model with up to third order interactions.
q = aov(strength~(speed+rate+grit+direction+batch)^3,data=df)
summary(q)

###>                       Df Sum Sq Mean Sq  F value    Pr(#>F)    
###> speed                  1    894     894   2.8175 0.1442496    
###> rate                   1   3497    3497  11.0175 0.0160190 *  
###> grit                   1  12664   12664  39.8964 0.0007354 ***
###> direction              1 315133  315133 992.7901 6.790e-08 ***
###> batch                  1  33654   33654 106.0229 4.901e-05 ***
###> speed:rate             1   4873    4873  15.3505 0.0078202 ** 
###> speed:grit             1   1839    1839   5.7928 0.0528018 .  
###> rate:grit              1    307     307   0.9686 0.3630334    
###> speed:direction        1   1637    1637   5.1578 0.0635727 .  
###> rate:direction         1   1973    1973   6.2148 0.0469744 *  
###> grit:direction         1   3158    3158   9.9500 0.0197054 *  
###> speed:batch            1    465     465   1.4651 0.2716372    
###> rate:batch             1    199     199   0.6274 0.4584725    
###> grit:batch             1     29      29   0.0925 0.7713116    
###> direction:batch        1   1329    1329   4.1863 0.0867147 .  
###> speed:rate:grit        1    357     357   1.1248 0.3296948    
###> speed:rate:direction   1   5896    5896  18.5735 0.0050391 ** 
###> speed:grit:direction   1      2       2   0.0067 0.9375734    
###> rate:grit:direction    1     44      44   0.1401 0.7210076    
###> speed:rate:batch       1    145     145   0.4559 0.5246982    
###> speed:grit:batch       1     30      30   0.0957 0.7675714    
###> rate:grit:batch        1     26      26   0.0806 0.7860488    
###> speed:direction:batch  1    545     545   1.7156 0.2381676    
###> rate:direction:batch   1    167     167   0.5271 0.4951683    
###> grit:direction:batch   1     32      32   0.1023 0.7599685    
###> Residuals              6   1905     317                       
###> ---
###> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 


## Stepwise regression based on AIC.
sreg = step(q,direction="backward")
summary(sreg)

###>                       Df Sum Sq Mean Sq   F value    Pr(#>F)    
###> speed                  1    894     894    5.1873 0.0418622 *  
###> rate                   1   3497    3497   20.2845 0.0007218 ***
###> grit                   1  12664   12664   73.4537 1.845e-06 ***
###> direction              1 315133  315133 1827.8368 1.742e-14 ***
###> batch                  1  33654   33654  195.1999 8.732e-09 ***
###> speed:rate             1   4873    4873   28.2620 0.0001834 ***
###> speed:grit             1   1839    1839   10.6652 0.0067561 ** 
###> speed:direction        1   1637    1637    9.4962 0.0095099 ** 
###> speed:batch            1    465     465    2.6974 0.1264405    
###> rate:grit              1    307     307    1.7833 0.2065205    
###> rate:direction         1   1973    1973   11.4421 0.0054417 ** 
###> rate:batch             1    199     199    1.1551 0.3036160    
###> grit:direction         1   3158    3158   18.3190 0.0010689 ** 
###> direction:batch        1   1329    1329    7.7075 0.0167669 *  
###> speed:rate:grit        1    357     357    2.0709 0.1756988    
###> speed:rate:direction   1   5896    5896   34.1959 7.866e-05 ***
###> speed:rate:batch       1    145     145    0.8394 0.3776229    
###> speed:direction:batch  1    545     545    3.1587 0.1008550    
###> rate:direction:batch   1    167     167    0.9704 0.3440214    
###> Residuals             12   2069     172                        
###> ---
###> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

## Remove non-significant terms from the stepwise model.
redmod = aov(formula = strength ~ speed + rate + grit + direction + 
            batch + speed:rate + speed:grit + speed:direction +  
            rate:direction + grit:direction + direction:batch + 
            speed:rate:direction, data = df)
summary(redmod)

###>                      Df Sum Sq Mean Sq   F value    Pr(#>F)    
###> speed                 1    894     894    3.9942 0.0601705 .  
###> rate                  1   3497    3497   15.6191 0.0008548 ***
###> grit                  1  12664   12664   56.5595 4.144e-07 ***
###> direction             1 315133  315133 1407.4388 < 2.2e-16 ***
###> batch                 1  33654   33654  150.3044 1.803e-10 ***
###> speed:rate            1   4873    4873   21.7618 0.0001688 ***
###> speed:grit            1   1839    1839    8.2122 0.0098962 ** 
###> speed:direction       1   1637    1637    7.3121 0.0140648 *  
###> rate:direction        1   1973    1973    8.8105 0.0078974 ** 
###> grit:direction        1   3158    3158   14.1057 0.0013383 ** 
###> direction:batch       1   1329    1329    5.9348 0.0248592 *  
###> speed:rate:direction  1   5896    5896   26.3309 5.934e-05 ***
###> Residuals            19   4254     224                        
###> ---
###> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1


## Print adjusted R squared.
summary.lm(redmod)$adj.r.squared

###> [1] 0.9822389
 

## Fit a model with all effects.
q = aov(strength~(speed+rate+grit+direction+batch)^5,data=df)

## Save effects in a vector, but remove intercept.
qef = q$effects
qef = qef[-1]

## Sort effects and save labels.
sef = qef[order(qef)]
qlab = names(sef)

## Leave off the two largest effects, Direction and Batch.
large = c(1,2)
sef = sef[-large]
qlab = qlab[-large]

## Generate theoretical quantiles.
ip = ppoints(length(sef))
zp = qnorm(ip)

## Generate normal probability plot of all effects (excluding the
## intercept).  Direction and batch are not shown.
par(bg=rgb(1,1,0.8))
plot(zp,sef, ylim=c(-120,70), xlim=c(-2,3),
     ylab="Effect", xlab="Theoretical Quantiles",
     main="Normal Probability Plot of Saturated Model Effects")
qqline(sef, col=2)
abline(h=0, col=4)
text(-2,90,"Direction and Batch not shown",pos=4)

## Add labels for largest 10 effects (two are not shown.
small = c(6:(length(sef)-3))
small2 = c((length(sef)-4):(length(sef)-3))
text(zp[-small],sef[-small],label=qlab[-small],pos=4,cex=0.8)
text(zp[small2],sef[small2],label=qlab[small2],pos=2,cex=0.8)
par(mfrow=c(1,1))


## Plot residuals versus predicted response.
par(bg=rgb(1,1,0.8))
plot(predict(redmod),redmod$residuals,ylab="Residual",
     xlab="Predicted Strength")
abline(h=0)
par(mfrow=c(1,1))

## Generate four plots.
par(mfrow=c(2,2),bg=rgb(1,1,0.8))
qqnorm(redmod$residuals)
qqline(redmod$residuals, col = 2)
abline(h=0)
boxplot(redmod$residuals, horizontal=TRUE, main="Box Plot", xlab="Residual")
hist(redmod$residuals, main="Histogram", xlab="Residual")
plot(order, redmod$residuals, xlab="Actual Run Order", ylab="Residual",
     main="Run Order Plot")
par(mfrow=c(1,1))


## Find the optimal Box-Cox transformation based on the 12 term model.
library(MASS)
par(bg=rgb(1,1,0.8))
bc = boxcox(redmod)
title("Box-Cox Transformation")
lambda = bc$x[which.max(bc$y)]
lambda
###> [1] 0.2626263

## Use lambda = 0.2 to match output in the page.
lambda = 0.2

par(mfrow=c(1,1))

## The optimum is found at lambda = 0.26.  A new variable, newstrength,
## is calculated and added to the data frame. 

## Attach psych library to compute the geometric mean of strength.
library(psych)

## Generate new transformed response variable and add to data frame.
newstrength = (strength^lambda - 1)/
              (lambda*(geometric.mean(strength)^(lambda-1)))
df =  data.frame(df,newstrength)


## Fit 12-term model with transformed strength variable.
summary(aov(formula = newstrength ~ speed + rate + grit + direction + 
            batch + speed:rate + speed:grit + speed:direction +  
            rate:direction + grit:direction + direction:batch + 
            speed:rate:direction, data = df))

###>                     Df Sum Sq Mean Sq   F value    Pr(#>F)    
###> speed                 1   1068    1068    5.4268 0.0310118 *  
###> rate                  1   4374    4374   22.2261 0.0001509 ***
###> grit                  1  14998   14998   76.2175 4.472e-08 ***
###> direction             1 315356  315356 1602.6361 < 2.2e-16 ***
###> batch                 1  32505   32505  165.1893 8.059e-11 ***
###> speed:rate            1   6697    6697   34.0362 1.279e-05 ***
###> speed:grit            1   1724    1724    8.7595 0.0080488 ** 
###> speed:direction       1   1654    1654    8.4036 0.0092010 ** 
###> rate:direction        1   2685    2685   13.6458 0.0015406 ** 
###> grit:direction        1   5379    5379   27.3375 4.784e-05 ***
###> direction:batch       1     76      76    0.3861 0.5417191    
###> speed:rate:direction  1   7516    7516   38.1937 6.139e-06 ***
###> Residuals            19   3739     197                        
###> ---
###> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1

## Add three-term interaction to data frame.
srd = s*r*d
df = data.frame(df,srd)

## Remove the direction:batch interaction since it's no longer
## significant.
newredmod = lm(formula = newstrength ~ s + r + sr +
            g + sg + d + ds + rd + srd + gd + b, data=df)
summary.lm(newredmod)

###> Call:
###> lm(formula = newstrength ~ s + r + sr + g + sg + d + ds + rd + 
###>     srd + gd + b, data = df)
###> 
###> Residuals:
###>     Min      1Q  Median      3Q     Max 
###> -29.468  -3.717  -1.389   6.560  20.294 
###> 
###> Coefficients:
###>             Estimate Std. Error t value Pr(#>|t|)    
###> (Intercept) 1917.115      2.441 785.252  < 2e-16 ***
###> s              5.777      2.441   2.366 0.028183 *  
###> r             11.691      2.441   4.789 0.000112 ***
###> sr            14.467      2.441   5.926 8.53e-06 ***
###> g            -21.649      2.441  -8.867 2.29e-08 ***
###> sg            -7.339      2.441  -3.006 0.006979 ** 
###> d            -99.272      2.441 -40.662  < 2e-16 ***
###> ds             7.189      2.441   2.944 0.008016 ** 
###> rd             9.160      2.441   3.752 0.001255 ** 
###> srd           15.325      2.441   6.277 3.96e-06 ***
###> gd           -12.965      2.441  -5.311 3.38e-05 ***
###> b            -31.871      2.441 -13.055 3.03e-11 ***
###> ---
###> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 

###> Residual standard error: 13.81 on 20 degrees of freedom
###> Multiple R-squared: 0.9904,     Adjusted R-squared: 0.9851 
###> F-statistic: 187.8 on 11 and 20 DF,  p-value: < 2.2e-16 


## Plot residuals versus predicted, transformed response.
par(mfrow=c(1,1),bg=rgb(1,1,0.8))
plot(predict(newredmod),newredmod$residuals,ylab="Residual",
     xlab="Predicted Transformed Strength")
abline(h=0)


## Generate four plots of residuals based on transformed response.
par(mfrow=c(2,2),bg=rgb(1,1,0.8))
qqnorm(newredmod$residuals)
qqline(newredmod$residuals, col = 2)
abline(h=0)
boxplot(newredmod$residuals, horizontal=TRUE, main="Box Plot", 
        xlab="Residual")
hist(newredmod$residuals, main="Histogram", xlab="Residual")
plot(order, newredmod$residuals, xlab="Actual Run Order", 
     ylab="Residual", main="Run Order Plot")
par(mfrow=c(1,1))


## Rearrange data so that factors and levels are in single columns.
n = length(df$strength[df$batch==1])
k = qt(.975,n-1)

group = rep(1:5,each=length(strength))
nstr = rep(newstrength,5)
level = c(m[,1],m[,2],m[,3],m[,4],m[,5])
dflong = data.frame(group,level,nstr)

gmn = aggregate(x=dflong$nstr,by=list(dflong$group,dflong$level),FUN="mean")
gsd = aggregate(x=dflong$nstr,by=list(dflong$group,dflong$level),FUN="sd")
cibar = k*gsd[3]/sqrt(n)
cgroup = rep(c("Speed","Rate","Grit","Direction","Batch"),2)

dfp = data.frame(cgroup,gmn,gsd[3],cibar)
names(dfp)=c("cgroup","group","level","tmean","std","cibar")


## Attach lattice library and generate main effects plot.
library(lattice)
par(mfrow=c(1,1))
xyplot(tmean~level|cgroup,data=dfp,layout=c(5,1),xlim=c(-2,2),
       ylab="Transformed Strength",xlab="Factor Levels", type="b",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = mean(newstrength), lty = 2, col = 2)})


## Generate two types of 2-way interaction plots.

## 2-way interaction plots showing overall effects.
group2 = rep(1:10,each=length(strength))
nstr2 = rep(newstrength,10)
level2 = c(db,gd,gb,rg,rd,rb,sr,sg,ds,sb)
df2way = data.frame(group2,level2,nstr2)

gmn2 = aggregate(x=df2way$nstr2,by=list(df2way$group2,df2way$level2),FUN="mean")
gsd2 = aggregate(x=df2way$nstr2,by=list(df2way$group2,df2way$level2),FUN="sd")

cgr2 = rep(c("d*b","g*d","g*b","r*g","r*d","r*b","s*r","s*g","s*d","s*b"),2)
dfp2 = data.frame(cgr2,gmn2,gsd2[3])
names(dfp2)=c("cgroup","group","level","tmean","std")

# Generate plot.
sp = c(T,T,T,F, T,T,F,F, T,F,F,F, F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)
xyplot(tmean~level | group, data=dfp2, type="b", xlim=c(-2,2),
       layout=c(4,4), skip=sp, col=c(4), ylim=c(1900,1935),
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=cgr2,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Transformed Strength",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = mean(newstrength), lty = 2, col = 2)})


## 2-way interaction plot showing means for all combinations of
## levels for the two factors.

## Compute means for plotting.
dfi = data.frame(s,r,g,d,b,newstrength)

mnsr = aggregate(x=dfi$newstrength,by=list(dfi$s,dfi$r),FUN="mean")
mnsg = aggregate(x=dfi$newstrength,by=list(dfi$s,dfi$g),FUN="mean")
mnsd = aggregate(x=dfi$newstrength,by=list(dfi$s,dfi$d),FUN="mean")
mnsb = aggregate(x=dfi$newstrength,by=list(dfi$s,dfi$b),FUN="mean")

mnrs = aggregate(x=dfi$newstrength,by=list(dfi$r,dfi$s),FUN="mean")
mnrg = aggregate(x=dfi$newstrength,by=list(dfi$r,dfi$g),FUN="mean")
mnrd = aggregate(x=dfi$newstrength,by=list(dfi$r,dfi$d),FUN="mean")
mnrb = aggregate(x=dfi$newstrength,by=list(dfi$r,dfi$b),FUN="mean")

mngs = aggregate(x=dfi$newstrength,by=list(dfi$g,dfi$s),FUN="mean")
mngr = aggregate(x=dfi$newstrength,by=list(dfi$g,dfi$r),FUN="mean")
mngd = aggregate(x=dfi$newstrength,by=list(dfi$g,dfi$d),FUN="mean")
mngb = aggregate(x=dfi$newstrength,by=list(dfi$g,dfi$b),FUN="mean")

mnds = aggregate(x=dfi$newstrength,by=list(dfi$d,dfi$s),FUN="mean")
mndr = aggregate(x=dfi$newstrength,by=list(dfi$d,dfi$r),FUN="mean")
mndg = aggregate(x=dfi$newstrength,by=list(dfi$d,dfi$g),FUN="mean")
mndb = aggregate(x=dfi$newstrength,by=list(dfi$d,dfi$b),FUN="mean")

mnbs = aggregate(x=dfi$newstrength,by=list(dfi$b,dfi$s),FUN="mean")
mnbr = aggregate(x=dfi$newstrength,by=list(dfi$b,dfi$r),FUN="mean")
mnbg = aggregate(x=dfi$newstrength,by=list(dfi$b,dfi$g),FUN="mean")
mnbd = aggregate(x=dfi$newstrength,by=list(dfi$b,dfi$d),FUN="mean")

xcol = rbind(mnbs,mnbr,mnbg,mnbd, mnds,mndr,mndg,mndb,
       mngs,mngr,mngd,mngb, mnrs,mnrg,mnrd,mnrb, mnsr,mnsg,mnsd,mnsb)
gi = rep(c("b*s","b*r","b*g","b*d",
           "d*s","d*r","d*g","d*b",
           "g*s","g*r","g*d","g*b",
           "r*s","r*g","r*d","r*b",
           "s*r","s*g","s*d","s*b"),each=4)
dff = data.frame(gi,xcol)

## Generate the lattice plot.
sp = c(T,F,F,F,F, F,T,F,F,F, F,F,T,F,F, F,F,F,T,F, F,F,F,F,T)
xyplot(x ~ Group.1 | gi, data=dff, group=Group.2,
       layout=c(5,5), skip=sp, xlim=c(-2,2),
       ylab = "Transformed Strength", xlab = "Factor Level",
       main = "Blue: low level, Pink: high level",
       type=c("p","l"), pch=20, cex=1, col=c(4,6),
       panel=function(x,y,...){panel.superpose(x,y,...)})
trellis.focus("toplevel") ## has coordinate system [0,1] x [0,1]
panel.text(0.200, 0.200, "Batch",     cex=1)
panel.text(0.365, 0.365, "Direction", cex=1)
panel.text(0.515, 0.515, "Grit",      cex=1)
panel.text(0.675, 0.675, "Rate",      cex=1)
panel.text(0.825, 0.825, "Speed",     cex=1)
trellis.unfocus()



#R commands and output:

## Specify fitted models.
y1 = function (x) {
    return(-1*(35.4*x[1] + 42.77*x[2] + 70.36*x[3] + 16.02*x[1]*x[2] +
           36.33*x[1]*x[3] + 136.8*x[2]*x[3] + 854.9*x[1]*x[2]*x[3]))
}

y2 = function (x) {
    3.88*x[1] + 9.03*x[2] + 13.63*x[3] - 0.1904*x[1]*x[2] -
        16.61*x[1]*x[3] - 27.67*x[2]*x[3]
}

y3 = function (x) {
        23.13*x[1] + 19.73*x[2] + 14.73*x[3]}

## Attach Rsolnp library for the optimization.
require(Rsolnp)

## Define constraints.
eqc = function (x) {sum(x)}
eqc.b = 1

ineqc = function (x) {c(y2(x), y3(x))}
ineqc.ub = c(4.5, 20)
ineqc.lb = c(-Inf, -Inf)

x.lb = c(0, 0, 0)
x.ub = c(1, 1, 1)

## Run solnp to perform optimization.
os = solnp(pars=c(0.2, 0.2, 0.4), fun=y1, eqfun=eqc, eqB=eqc.b,
           ineqfun=ineqc, ineqLB=ineqc.lb, ineqUB=ineqc.ub,
           LB=x.lb, UB=x.ub)

## Print results.
x = os$pars
cbind(x, c(-y1(x), y2(x), y3(x)))

#>  0.2123296 106.621508
#>  0.3437247   4.176745
#>  0.4439457  18.232192

## Test that the sum of the x variables is one.
sum(x)

#> 1

#R code and output:

## Input data.
m = matrix(
c(0.0, 0.0, 1.0, 16.8,
0.0, 0.0, 1.0, 16.0,
0.0, 0.5, 0.5, 10.0,
0.0, 0.5, 0.5,  9.7,
0.0, 0.5, 0.5, 11.8,
0.0, 1.0, 0.0,  8.8,
0.0, 1.0, 0.0, 10.0,
0.5, 0.0, 0.5, 17.7,
0.5, 0.0, 0.5, 16.4,
0.5, 0.0, 0.5, 16.6,
0.5, 0.5, 0.0, 15.0,
0.5, 0.5, 0.0, 14.8,
0.5, 0.5, 0.0, 16.1,
1.0, 0.0, 0.0, 11.0,
1.0, 0.0, 0.0, 12.4), ncol=4, byrow=T)

x1 = m[,1]
x2 = m[,2]
x3 = m[,3]
y  = m[,4]


## Fit model to data.
m1 = lm(y ~ -1 + x1 + x2 + x3 + x1*x2 + x1*x3 + x2*x3)

## Combine model effects for F test.
q = anova(m1)
mss = sum(q[1:6,2])
mdof = round(sum(q[1:6,1]),1)
mmse = mss/mdof
rss = q[7,2]
rdof = q[7,1]
mse = rss/rdof

## Combine and print results.
residual = c(rdof,rss,mse,NA,NA)
model = c(mdof,mss,mmse,mmse/mse,df(mmse/mse,mdof,rdof))
a = data.frame(rbind(model,residual))
names(a) = c("DOF","Sum-of-Squares","MSE","F Value","Prob #> F")
a

#>          DOF Sum-of-Squares         MSE F Value     Prob #> F
#> model      6        2878.27 479.7116667 658.141 1.547746e-13
#> residual   9           6.56   0.7288889      NA           NA

## Print summary of model fit.
summary(m1)

#> Call:
#> lm(formula = y ~ -1 + x1 + x2 + x3 + x1 * x2 + x1 * x3 + x2 * 
#>     x3)
#>
#> Residuals:
#>    Min     1Q Median     3Q    Max 
#>  -0.80  -0.50  -0.30   0.65   1.30 
#>
#> Coefficients:
#>       Estimate Std. Error t value Pr(#>|t|)    
#> x1     11.7000     0.6037  19.381 1.20e-08 ***
#> x2      9.4000     0.6037  15.571 8.15e-08 ***
#> x3     16.4000     0.6037  27.166 6.01e-10 ***
#> x1:x2  19.0000     2.6082   7.285 4.64e-05 ***
#> x1:x3  11.4000     2.6082   4.371  0.00180 ** 
#> x2:x3  -9.6000     2.6082  -3.681  0.00507 ** 
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 0.8537 on 9 degrees of freedom
#> Multiple R-squared: 0.9977,     Adjusted R-squared: 0.9962 
#> F-statistic: 658.1 on 6 and 9 DF,  p-value: 2.271e-11 


## Generate triangular plot.
## Attach lattice library.
library(lattice)

## Generate triangular area for plotting.
trian <- expand.grid(base=seq(0,1,l=100*2), high=seq(0,sin(pi/3),l=87*2))
trian <- subset(trian, (base*sin(pi/3)*2)>high)
trian <- subset(trian, ((1-base)*sin(pi/3)*2)>high)

new <- data.frame(x2=trian$high*2/sqrt(3))
new$x3 <- trian$base-trian$high/sqrt(3)
new$x1 <- 1-new$x3-new$x2

## Predict triangular surface based on regression model.
trian$yhat <- predict(m1, newdata=new)

## Create function to place grid lines and axis labels on the plot.
grade.trellis <- function(from=0.2, to=0.8, step=0.2, col=1, lty=2, lwd=0.5){
  x1 <- seq(from, to, step)
  x2 <- x1/2
  y2 <- x1*sqrt(3)/2
  x3 <- (1-x1)*0.5+x1
  y3 <- sqrt(3)/2-x1*sqrt(3)/2
  panel.segments(x1, 0, x2, y2, col=col, lty=lty, lwd=lwd)
  panel.text(x1, 0, label=x1, pos=1)
  panel.segments(x1, 0, x3, y3, col=col, lty=lty, lwd=lwd)
  panel.text(x2, y2, label=rev(x1), pos=2)
  panel.segments(x2, y2, 1-x2, y2, col=col, lty=lty, lwd=lwd)
  panel.text(x3, y3, label=rev(x1), pos=4)
}

## Generate triangular contour plot.
levelplot(yhat~base*high, trian, aspect="iso", xlim=c(-0.1,1.1), ylim=c(-0.1,0.96),
          xlab=NULL, ylab=NULL, contour=TRUE, labels=FALSE, colorkey=TRUE,
          par.settings=list(axis.line=list(col=NA), axis.text=list(col=NA)))
trellis.focus("panel", 1, 1, highlight=FALSE)
panel.segments(c(0,0,0.5), c(0,0,sqrt(3)/2), c(1,1/2,1), c(0,sqrt(3)/2,0))
grade.trellis()
panel.text(.9,.45,label="x2",pos=2)
panel.text(.1,.45,label="x1",pos=4)
panel.text(.5,-.05,label="x3",pos=1)
trellis.unfocus()
#R commands and output:

## Eddy Current Probe Sensitivity Case Study

## Read and sort data.
mo = matrix(scan("../res/splett3.dat",skip=25),ncol=5,byrow=T)
m = mo[order(mo[,1]),]
y = m[,1]
x1 = m[,2]
x2 = m[,3]
x3 = m[,4]

## Attach memisc library for the recode function.
library(memisc)

## Generate re-coded factor variables for plotting.
r1 = recode(x1,"+" <- c(1),"-" <- c(-1))
r2 = recode(x2,"+" <- c(1),"-" <- c(-1))
r3 = recode(x3,"+" <- c(1),"-" <- c(-1))
id = paste(r1,r2,r3,sep="")
id1 = paste(r2,r3,sep="")
id2 = paste(r1,r3,sep="")
id3 = paste(r1,r2,sep="")

## Plot points in increasing order with labels indicating
## factor levels.
par(bg=rgb(1,1,0.8),mfrow=c(1,1), cex=1.2)
case = c(1:length(id))
plot(m[,1], xaxt = "n", col="blue", pch=19,
     main="Ordered Data Plot for Eddy Current Study",
     ylab="Sensitivity", xlab="Settings of X1 X2 X3")
axis(1, at=case, labels=id)

## Restructure data so that x1, x2, and x3 are in a single column.
## Also, save re-coded version of the factor levels for the mean plot.
tempx  = x1
tempxc = x1 + 1
dm1 = cbind(y,tempx,tempxc)
tempx  = x2
tempxc = x2 + 4
dm2 = cbind(y,tempx,tempxc)
tempx  = x3
tempxc = x3 + 7
dm3 = cbind(y,tempx,tempxc)
dm4 = rbind(dm1,dm2,dm3)

## Generate factor ID variable.
n = length(y)
varind = c(rep("Number of Turns",n),rep("Winding Distance",n),
           rep("Wire Gauge",n))
varind = as.factor(varind)

## Create a dataframe with "stacked" factors and data.
df = data.frame(dm4,varind)

## Attach lattice library and generate the DOE scatter plot.
par(bg=rgb(1,1,0.8),mfrow=c(1,1), cex=1.2)
library(lattice)
xyplot(y~tempx|varind,data=df,layout=c(3,1),xlim=c(-2,2), pch=19,
       ylab="Sensitivity",xlab="Factor Levels",
       main="DOE Scatter Plot for Eddy Current Data")

## Comute grand mean.
ybar = mean(y)

## Generate mean plot.
par(bg=rgb(1,1,0.8),mfrow=c(1,1), cex=1.2)
interaction.plot(df$tempxc,df$varind,df$y,fun=mean,
                 ylab="Sensitivity",xlab="",
                 main="DOE Mean Plot for Eddy Current Data",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5)
xlabel = c("Number of Turns","Winding Distance","Wire Gauge")
axis(side=1,at=xpos,labels=xlabel)
abline(h=ybar)

## Create dataframe with interaction factors.
x12 = x1*x2
x13 = x1*x3
x23 = x2*x3
x123 = x1*x2*x3
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
fx12 = factor(x12)
fx13 = factor(x13)
fx23 = factor(x23)
fx123 = factor(x123)
dfip = data.frame(y,fx1,fx2,fx3,fx12,fx13,fx23,fx123)

## Compute effect estimates and factor means.
q = aggregate(x=dfip$y,by=list(dfip$fx1),FUN="mean")
x1lo = q[1,2]
x1hi = q[2,2]
e1 = x1lo-x1hi

q = aggregate(x=dfip$y,by=list(dfip$fx2),FUN="mean")
x2lo = q[1,2]
x2hi = q[2,2]
e2 = x2lo - x2hi

q = aggregate(x=dfip$y,by=list(dfip$fx3),FUN="mean")
x3lo = q[1,2]
x3hi = q[2,2]
e3 = x3lo - x3hi

q = aggregate(x=dfip$y,by=list(dfip$fx12),FUN="mean")
x12lo = q[1,2]
x12hi = q[2,2]
e12 = x12lo - x12hi

q = aggregate(x=dfip$y,by=list(dfip$fx13),FUN="mean")
x13lo = q[1,2]
x13hi = q[2,2]
e13 = x13lo - x13hi

q = aggregate(x=dfip$y,by=list(dfip$fx23),FUN="mean")
x23lo = q[1,2]
x23hi = q[2,2]
e23 = x23lo - x23hi

# Create factor labels from effect values.
e = round(c(e3,e2,e23,e1,e12,e13),2)
textlabs = c("X3 Effect =","X2 Effect =","X2*X3 Effect =",
             "X1 Effect =","X1*X2 Effect =","X1*X3 Effect =")
labs = paste(textlabs,e)
group = factor(c(1:6),labels=labs)

# Create data frame with factor level means.
x = c(x3lo,x2lo,x23lo,x1lo,x12lo,x13lo)
xlev = rep(-1,6)
xlo = cbind(x,xlev,group)

x = c(x3hi,x2hi,x23hi,x1hi,x12hi,x13hi)
xlev = rep(1,6)
xhi = cbind(x,xlev,group)

m = rbind(xlo,xhi)
m = as.data.frame(m)

# Customize Lattice plot layout and color.
sp = c(T,T,F,T,F,F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)

# Generate plot.
xyplot(x~xlev | group, data=m, type="b", xlim=c(-2,2),
       layout=c(3,3), skip=sp, col=c(4), pch=19,
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=labs,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Sensitivity", 
       main="DOE Interaction Plot for Eddy Current Data",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = ybar, lty = 2, col = 2)
}
)

## Create dataframe with factors.
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
fid1 = factor(id1)
fid2 = factor(id2)
fid3 = factor(id3)
df2 = data.frame(y,fx1,fx2,fx3,fid1,fid2,fid3)

## Generate four plots on one page.
par(bg=rgb(1,1,0.8),mfrow=c(2,2),cex=1)

## Generate the block plot for factor 1 - number of turns.
boxplot(df2$y ~ df2$fid1, medlty="blank", boxwex=.5,
        ylab="Sensitivity",xlab="Factor Levels of X2 X3",
        main="Primary Factor X1", cex.main=1)
## Add points for the effects.
points(df2$fid1[df2$fx1==1],df2$y[df2$fx1==1],pch=19,col="blue")
points(df2$fid1[df2$fx1==-1],df2$y[df2$fx1==-1],col="blue")
## Add legend.
legend(0.35,1.5,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X1 Level", cex=.7, horiz=TRUE)

## Generate the block plot for factor 2 - winding distance.
boxplot(df2$y ~ df2$fid2, medlty="blank", boxwex=.5,
        ylab="Sensitivity",xlab="Factor Levels of X1 X3",
        main="Primary Factor X2", cex.main=1)
## Add points for the effect means.
points(df2$fid2[df2$fx2==1],df2$y[df2$fx2==1],pch=19,col="blue")
points(df2$fid2[df2$fx2==-1],df2$y[df2$fx2==-1],col="blue")
## Add legend.
legend(0.35,4.7,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X2 Level", cex=.7, horiz=TRUE)

## Generate the block plot for factor 3 - wire gauge.
boxplot(df2$y ~ df2$fid3, medlty="blank", boxwex=.5, 
        ylab="Sensitivity",xlab="Factor Levels of X1 X2",
        main="Primary Factor X3", cex.main=1)
## Add points for the effects.
points(df2$fid3[df2$fx3==1],df2$y[df2$fx3==1],pch=19,col="blue")
points(df2$fid3[df2$fx3==-1],df2$y[df2$fx3==-1],col="blue")
## Add legend.
legend(0.35,4.7,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X3 Level", cex=.7, horiz=TRUE)
par(mfrow=c(1,1))


## Re-enter data for Yates' analysis. 
m = matrix(scan("../res/splett3.dat",skip=25),ncol=5,byrow=T)
y = m[,1]
x1 = m[,2]
x2 = m[,3]
x3 = m[,4]

## Compute the pseudo-replication standard deviation 
## (assuming all 3rd order and higher interactions are 
## really due to random error).
z = lm(y ~ 1 + x1 + x2 + x3 + x1*x2 + x1*x3 + x2*x3)
summary(z)$sigma

#> [1] 0.2015254

## Save t-values based on pseudo-replication standard deviation.
t1 = summary(z)$coefficients[2,3]
t2 = summary(z)$coefficients[3,3]
t23 = summary(z)$coefficients[7,3]
t13 = summary(z)$coefficients[6,3]
t3 = summary(z)$coefficients[4,3]
t123 = 1
t12 = summary(z)$coefficients[5,3]
Tvalue = round(rbind(NaN,t1,t2,t23,t13,t3,t123,t12),2)

## Compute the effect estimate and residual standard deviation
## for each model (mean plus the effect).
z = lm(y ~ 1)
avg = summary(z)$coefficients[1]
ese = summary(z)$sigma

z = lm(y ~ 1 + x1)
e1 = summary(z)$coefficients[2]
e1se = summary(z)$sigma

z = lm(y ~ 1 + x2)
e2 = summary(z)$coefficients[2]
e2se = summary(z)$sigma

z = lm(y ~ 1 + x2:x3)
e23 = summary(z)$coefficients[2]
e23se = summary(z)$sigma

z = lm(y ~ 1 + x1:x3)
e13 = summary(z)$coefficients[2]
e13se = summary(z)$sigma

z = lm(y ~ 1 + x3)
e3 = summary(z)$coefficients[2]
e3se = summary(z)$sigma

z = lm(y ~ 1 + x1:x2:x3)
e123 = summary(z)$coefficients[2]
e123se = summary(z)$sigma

z = lm(y ~ 1 + x1:x2)
e12 = summary(z)$coefficients[2]
e12se = summary(z)$sigma

Effect = rbind(avg,e1,e2,e23,e13,e3,e123,e12)
Eff.SE = rbind(ese,e1se,e2se,e23se,e13se,e3se,e123se,e12se)

## Compute the residual standard deviation for cumulative
## models (mean plus cumulative terms).

z = lm(y ~ 1)
ce = summary(z)$sigma
z = lm(y ~ 1 + x1)
ce1 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2)
ce2 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2 + x2:x3)
ce3 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2 + x2:x3 + x1:x3)
ce4 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2 + x2:x3 + x1:x3 + x3)
ce5 = summary(z)$sigma
z = lm(y ~ x1 + x2 + x2:x3 + x1:x3 + x3 + x1:x2:x3)
ce6 = summary(z)$sigma
z = lm(y ~ 1 + x1*x2*x3)
ce7 = summary(z)$sigma

Cum.Eff = rbind(ce,ce1,ce2,ce3,ce4,ce5,ce6,ce7)

## Combine the results into a dataframe.
round(data.frame(Effect, Tvalue, Eff.SE, Cum.Eff),5)

#>        Effect Tvalue  Eff.SE Cum.Eff
#> avg   2.65875    NaN 1.74106 1.74106
#> e1    1.55125  21.77 0.57272 0.57272
#> e2   -0.43375  -6.09 1.81264 0.30429
#> e23   0.14875   2.09 1.87270 0.26737
#> e13   0.12375   1.74 1.87513 0.23341
#> e3    0.10625   1.49 1.87656 0.19121
#> e123  0.07125   1.00 1.87876 0.18031
#> e12   0.06375   0.89 1.87912     NaN

## Compute effect estimates and print.
z = lm(y ~ 1 + x1 + x2 + x3 + x1*x2 + x1*x3 + x2*x3 + x1*x2*x3)
effects = coef(z)
effects

#> (Intercept)         x1          x2          x3       x1:x2       x1:x3 
#>    2.65875     1.55125    -0.43375     0.10625     0.06375     0.12375 
#>      x2:x3    x1:x2:x3 
#>    0.14875     0.07125

## Generate half-normal probability plot of effect estimates.
par(bg=rgb(1,1,0.8),mfrow=c(1,1), cex=1.2)
qqnorm((effects[-1]), pch=19, col="blue",
         main="Normal Probability Plot of Eddy Current Data")

## Generate Youden plot.
## Create dataframe with interaction factors.
x12 = x1*x2
x13 = x1*x3
x23 = x2*x3
x123 = x1*x2*x3
fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
fx12 = factor(x12)
fx13 = factor(x13)
fx23 = factor(x23)
fx123 = factor(x123)
dfip = data.frame(y,fx1,fx2,fx3,fx12,fx13,fx23,fx123)

## Generate averages for each factor and level.
q1 = aggregate(x=dfip$y,by=list(dfip$fx1),FUN="mean")
qt1 = t(q1$x)
q2 = aggregate(x=dfip$y,by=list(dfip$fx2),FUN="mean")
qt2 = t(q2$x)
q3 = aggregate(x=dfip$y,by=list(dfip$fx3),FUN="mean")
qt3 = t(q3$x)
q4 = aggregate(x=dfip$y,by=list(dfip$fx12),FUN="mean")
qt4 = t(q4$x)
q5 = aggregate(x=dfip$y,by=list(dfip$fx13),FUN="mean")
qt5 = t(q5$x)
q6 = aggregate(x=dfip$y,by=list(dfip$fx23),FUN="mean")
qt6 = t(q6$x)
q7 = aggregate(x=dfip$y,by=list(dfip$fx23),FUN="mean")
qt7 = t(q7$x)
yp = rbind(qt1,qt2,qt3,qt4,qt5,qt6,qt7)
yp

#>        [,1]   [,2]
#> [1,] 1.1075 4.2100
#> [2,] 3.0925 2.2250
#> [3,] 2.5525 2.7650
#> [4,] 2.5950 2.7225
#> [5,] 2.5350 2.7825
#> [6,] 2.5100 2.8075
#> [7,] 2.5100 2.8075

## Generate plot.
par(bg=rgb(1,1,0.8),mfrow=c(1,1), cex=1.2)
plot(yp[,1],yp[,2], xlim=c(1,5), ylim=c(1,5),
     xlab="Average Response for -1 Settings",
     ylab="Average Response for +1 Settings",
     main="Youden Plot for Eddy Current Data")
text(yp[,1],yp[,2],labels=names(effects[-1]),pos=4)

## Fit model with x1 and x2.
z = lm(y ~ 1 + x1 + x2)
summary(z)

#> Call:
#> lm(formula = y ~ 1 + x1 + x2)
#> 
#> Residuals:
#>        1        2        3        4        5        6        7        8 
#>  0.15875 -0.07375 -0.12375 -0.38625 -0.03125 -0.05375 -0.00375  0.51375 
#> 
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)   2.6587     0.1076  24.714 2.02e-06 ***
#> x1            1.5512     0.1076  14.419 2.89e-05 ***
#> x2           -0.4337     0.1076  -4.032     0.01 *  
#> ---
#> Signif. codes:  0 \91***\92 0.001 \91**\92 0.01 \91*\92 0.05 \91.\92 0.1 \91 \92 1 
#> 
#> Residual standard error: 0.3043 on 5 degrees of freedom
#> Multiple R-squared: 0.9782,     Adjusted R-squared: 0.9695 
#> F-statistic: 112.1 on 2 and 5 DF,  p-value: 7.031e-05 

## Predict value for x1=-1 and x2 = -1.
predict(z,data.frame(x1=-1,x2=-1))

#>       1 
#> 1.54125

## Print residuals.
res = data.frame(x1,x2,x3,y,predict(z),z$residuals)
names(res)=c("x1","x2","x3","Observed","Predicted","Residual")
res

#>   x1 x2 x3 Observed Predicted Residual
#> 1 -1 -1 -1     1.70   1.54125  0.15875
#> 2  1 -1 -1     4.57   4.64375 -0.07375
#> 3 -1  1 -1     0.55   0.67375 -0.12375
#> 4  1  1 -1     3.39   3.77625 -0.38625
#> 5 -1 -1  1     1.51   1.54125 -0.03125
#> 6  1 -1  1     4.59   4.64375 -0.05375
#> 7 -1  1  1     0.67   0.67375 -0.00375
#> 8  1  1  1     4.29   3.77625  0.51375

## Generate residual plots.
par(bg=rgb(1,1,0.8),mfrow=c(3,3), pch=19, cex=.7)
rlab = "Residual"
qqnorm(z$residuals)
plot(z$residuals,type="l",main="Run Sequence",ylab=rlab)
plot(x1,z$residuals,ylab=rlab,xlim=c(-2,2))
plot(x2,z$residuals,ylab=rlab,xlim=c(-2,2))
plot(x3,z$residuals,ylab=rlab,xlim=c(-2,2))
plot(x1*x2,z$residuals,ylab=rlab,xlim=c(-2,2))
plot(x1*x3,z$residuals,ylab=rlab,xlim=c(-2,2))
plot(x2*x3,z$residuals,ylab=rlab,xlim=c(-2,2))
plot(x1*x2*x3,z$residuals,ylab=rlab,xlim=c(-2,2))
par(mfrow=c(1,1))

## Generate level means for plotting.
q = aggregate(x=dfip$y,by=list(dfip$fx1,dfip$fx2),FUN="mean")
qv1 = as.vector(q$Group.1,mode="numeric")-1
qv2 = as.vector(q$Group.2,mode="numeric")-1
qv1[qv1==0] = -1
qv2[qv2==0] = -1

## Contour plot y(x1=number of turns),x(x2= winding distance)
## Generate x and y data for plotting.
xord = seq(-2,2,by=.1)
yord = seq(-2,2,by=.1)

## Generate predicted response surface and generate matrix of surface.
model = function (a, b){
  z$coefficients[1] +
  z$coefficients[2]*a +
  z$coefficients[3]*b}
pmatu = outer(xord,yord,model)

## Generate contour plot, add design points and labels.
par(bg=rgb(1,1,0.8),mfrow=c(1,1), cex=1.2)
contour(xord, yord, pmatu, nlevels=30, main="Contour Plot",
        xlab="Winding Distance", ylab="Number of Turns",
        col="blue")
points(qv1,qv2,pch=19)
text(c(qv1[1],qv1[3]),c(qv2[1],qv2[3]),labels=c(q$x[1],q$x[3]),pos=2)
text(c(qv1[2],qv1[4]),c(qv2[2],qv2[4]),labels=c(q$x[2],q$x[4]),pos=4)
lines(c(-1,1,1,-1,-1),c(-1,-1,1,1,-1))
#R commands and output:

# Sonoluminescense Light Intensity Case Study.

# Read and sort data.
fname = "../res/inn.dat"
mo = matrix(scan(fname,skip=25),ncol=8,byrow=T)
m = mo[order(mo[,1]),]
y = m[,1]
x1 = m[,2]
x2 = m[,3]
x3 = m[,4]
x4 = m[,5]
x5 = m[,6]
x6 = m[,7]
x7 = m[,8]

## Attach memisc library for the recode function.
#install.packages("memisc", repos="http://R-Forge.R-project.org")
library(memisc)

## Generate re-coded factor variables for plotting.
r0 = "12345678"
r1 = recode(x1,"+" <- c(1),"-" <- c(-1))
r2 = recode(x2,"+" <- c(1),"-" <- c(-1))
r3 = recode(x3,"+" <- c(1),"-" <- c(-1))
r4 = recode(x4,"+" <- c(1),"-" <- c(-1))
r5 = recode(x5,"+" <- c(1),"-" <- c(-1))
r6 = recode(x6,"+" <- c(1),"-" <- c(-1))
r7 = recode(x7,"+" <- c(1),"-" <- c(-1))
id = paste(r1,r2,r3,r4,r5,r6,r7,sep="")
id = c(r0,id)
id12 = paste(r1,r2,sep="")
id13 = paste(r1,r3,sep="")
id14 = paste(r1,r4,sep="")
id15 = paste(r1,r5,sep="")
id16 = paste(r1,r6,sep="")
id17 = paste(r1,r7,sep="")
id23 = paste(r2,r3,sep="")
id24 = paste(r2,r4,sep="")
id25 = paste(r2,r5,sep="")
id26 = paste(r2,r6,sep="")
id27 = paste(r2,r7,sep="")
id34 = paste(r3,r4,sep="")
id35 = paste(r3,r5,sep="")
id36 = paste(r3,r6,sep="")
id37 = paste(r3,r7,sep="")
id45 = paste(r4,r5,sep="")
id46 = paste(r4,r6,sep="")
id47 = paste(r4,r7,sep="")
id56 = paste(r5,r6,sep="")
id57 = paste(r5,r7,sep="")
id67 = paste(r6,r7,sep="")

## Plot points in increasing order with labels indicating
## factor levels.
par(cex=1.25,las=3)
case = c(1:length(id))
plot(c(NA,m[,1]), xaxt = "n", col="blue", pch=19,
     main="Ordered Sonoluminescence Light Intensity Data",
     ylab="Light Intensity", xlab="")
axis(1, at=case, labels=id)

## Restructure data so that x1, x2, ... x7 are in a single column.
## Also, save re-coded version of the factor levels for the mean plot.
tempx  = x1
tempxc = x1 + 1
dm1 = cbind(y,tempx,tempxc)
tempx  = x2
tempxc = x2 + 4
dm2 = cbind(y,tempx,tempxc)
tempx  = x3
tempxc = x3 + 7
dm3 = cbind(y,tempx,tempxc)
tempx  = x4
tempxc = x4 + 10
dm4 = cbind(y,tempx,tempxc)
tempx  = x5
tempxc = x5 + 13
dm5 = cbind(y,tempx,tempxc)
tempx  = x6
tempxc = x6 + 16
dm6 = cbind(y,tempx,tempxc)
tempx  = x7
tempxc = x7 + 19
dm7 = cbind(y,tempx,tempxc)
dm8 = rbind(dm1,dm2,dm3,dm4,dm5,dm6,dm7)

## Generate factor ID variable.
n = length(y)
varind = c(rep("Molarity",n),
           rep("Solute Type",n),
           rep("pH",n),
           rep("Gas Type",n),
           rep("Water Depth",n),
           rep("Horn Depth",n),
           rep("Flask Clamping",n))
varind = as.factor(varind)

## Comute grand mean.
ybar = mean(y)

## Create a dataframe with "stacked" factors and data.
df = data.frame(dm8,varind)

## Attach lattice library and generate the DEX scatter plot.
library(lattice)
xyplot(y~tempx|varind,data=df,layout=c(4,2),xlim=c(-2,2),
       ylab="Light Intensity",xlab="Factor Levels",
       main="Scatter Plot for Sonoluminescense Light Intensity",
	 panel=function(x,y, ...){
		panel.xyplot(x,y, ...)
		panel.abline(h=ybar) }
)

## Generate mean plot.
par(cex=1,las=3)
interaction.plot(df$tempxc,df$varind,df$y,fun=mean,
                 ylab="Average Light Intensity",xlab="",
                 main="DEX Mean Plot for Sonoluminescense Light Intensity",
                 trace.label="Factor",type="b",pch=19,
                 legend=FALSE,xaxt="n")
xpos = c(1.5,3.5,5.5,7.5,9.5,11.5,13.5)
xlabel = c("Molarity","Solute","pH","Gas Type","Water",
           "Horn","Flask")
axis(side=1,at=xpos,labels=xlabel)
abline(h=ybar)


## Create dataframe with interaction factors.
x12 = x1*x2
x13 = x1*x3
x14 = x1*x4
x15 = x1*x5
x16 = x1*x6
x17 = x1*x7
x23 = x2*x3
x24 = x2*x4
x25 = x2*x5
x26 = x2*x6
x27 = x2*x7
x34 = x3*x4
x35 = x3*x5
x36 = x3*x6
x37 = x3*x7
x45 = x4*x5
x46 = x4*x6
x47 = x4*x7
x56 = x5*x6
x57 = x5*x7
x67 = x6*x7
x124 = x1*x2*x4

fx1 = factor(x1)
fx2 = factor(x2)
fx3 = factor(x3)
fx4 = factor(x4)
fx5 = factor(x5)
fx6 = factor(x6)
fx7 = factor(x7)
fx12 = factor(x12)
fx13 = factor(x13)
fx14 = factor(x14)
fx15 = factor(x15)
fx16 = factor(x16)
fx17 = factor(x17)
fx23 = factor(x23)
fx24 = factor(x24)
fx25 = factor(x25)
fx26 = factor(x26)
fx27 = factor(x27)
fx34 = factor(x34)
fx35 = factor(x35)
fx36 = factor(x36)
fx37 = factor(x37)
fx45 = factor(x45)
fx46 = factor(x46)
fx47 = factor(x47)
fx56 = factor(x56)
fx57 = factor(x57)
fx67 = factor(x67)
fx124 = factor(x124)
dfip = data.frame(y,fx1,fx2,fx3,fx4,fx5,fx6,fx7,
                  fx12,fx13,fx14,fx15,fx16,fx17,
                  fx23,fx24,fx25,fx26,fx27,
                  fx34,fx35,fx36,fx37,
                  fx45,fx46,fx47,
                  fx56,fx57,
                  fx67,fx124)

## Compute effect estimates and factor means.
fmeans = function(x,fac){
q = aggregate(x=x,by=list(fac),FUN="mean")
lo = q[1,2]
hi = q[2,2]
e = hi-lo
ret = c(lo,hi,e)
}
e1 = fmeans(dfip$y,dfip$fx1)
e2 = fmeans(dfip$y,dfip$fx2)
e3 = fmeans(dfip$y,dfip$fx3)
e4 = fmeans(dfip$y,dfip$fx4)
e5 = fmeans(dfip$y,dfip$fx5)
e6 = fmeans(dfip$y,dfip$fx6)
e7 = fmeans(dfip$y,dfip$fx7)
e12 = fmeans(dfip$y,dfip$fx12)
e13 = fmeans(dfip$y,dfip$fx13)
e14 = fmeans(dfip$y,dfip$fx14)
e15 = fmeans(dfip$y,dfip$fx15)
e16 = fmeans(dfip$y,dfip$fx16)
e17 = fmeans(dfip$y,dfip$fx17)
e23 = fmeans(dfip$y,dfip$fx23)
e24 = fmeans(dfip$y,dfip$fx24)
e25 = fmeans(dfip$y,dfip$fx25)
e26 = fmeans(dfip$y,dfip$fx26)
e27 = fmeans(dfip$y,dfip$fx27)
e34 = fmeans(dfip$y,dfip$fx34)
e35 = fmeans(dfip$y,dfip$fx35)
e36 = fmeans(dfip$y,dfip$fx36)
e37 = fmeans(dfip$y,dfip$fx37)
e45 = fmeans(dfip$y,dfip$fx45)
e46 = fmeans(dfip$y,dfip$fx46)
e47 = fmeans(dfip$y,dfip$fx47)
e56 = fmeans(dfip$y,dfip$fx56)
e57 = fmeans(dfip$y,dfip$fx57)
e67 = fmeans(dfip$y,dfip$fx67)

# Create factor labels from effect values.
e = round(rbind(e7,e6,e67,e5,e56,e57,e4,e45,e46,e47,
            e3,e34,e35,e36,e37,e2,e23,e24,e25,e26,e27,
            e1,e12,e13,e14,e15,e16,e17),1)
textlabs = c("X7 =", 
             "X6 =", "X67 =",
             "X5 =", "X56 =", "X57 =", 
             "X4 =", "X45 =", "X46 =", "X47 =",
             "X3 =", "X34 =", "X35 =", "X36 =", "X37 =",
             "X2 =", "X23 =", "X24 =", "X25 =", "X26 =", "X27 =",
             "X1 =", "X12 =", "X13 =", "X14 =", "X15 =", "X16 =", "X17 =")
labs = paste(textlabs,e[,3])
group = factor(c(1:28),labels=labs)

# Create data frame with factor level means.
x = e[,1]
xlev = rep(-1,28)
xlo = cbind(x,xlev,group)

x = e[,2]
xlev = rep(1,28)
xhi = cbind(x,xlev,group)

mm = rbind(xlo,xhi)
mm = as.data.frame(mm)

# Customize Lattice plot layout and color.
sp = c(T,T,T,T,T,T,F,
       T,T,T,T,T,F,F,
       T,T,T,T,F,F,F,
       T,T,T,F,F,F,F,
       T,T,F,F,F,F,F,
       T,F,F,F,F,F,F,
       F,F,F,F,F,F,F)
strip.bg_custom = trellis.par.get("strip.background")
strip.bg_custom$col =c("#cce6ff","#ffe5cc","#ccffcc","#ccffff","#ffccff",
                       "#ffcccc","#ffffcc")
strip.sh_custom = strip.bg_custom
trellis.par.set("strip.background", strip.bg_custom)
trellis.par.set("strip.shingle", strip.sh_custom)

trellis.par.set(list(fontsize=list(text=10)))

# Generate plot.
xyplot(x~xlev | group, data=mm, type="b", xlim=c(-2,2),
       layout=c(7,7), skip=sp, col=c(4), 
       strip = function(..., style,factor.levels,strip.levels,strip.names)
               strip.default(..., style = 1,factor.levels=labs,
                             strip.levels=c(F,T),strip.names=c(T,F)),
       xlab="Factor Level", ylab="Light Intensity", 
       main="DEX Mean Plot for Sonoluminescense Light Intensity",
panel = function(x, y, ...){
panel.xyplot(x, y, ...)
panel.abline(h = ybar, lty = 2, col = 2)
}
)



## Create dataframe with factors.
fid1 = factor(id23)
fid2 = factor(id13)
fid3 = factor(id12)
df2 = data.frame(y,fx1,fx2,fx3,fx4,fx5,fx6,fx7,
                fid1,fid2,fid3)

## Generate seven plots on one page.
par(mfrow=c(3,3),las=0)

## Generate level means.
ag = aggregate(x=df2$y,by=list(df2$fx1,df2$fx2,df2$fx3),FUN="mean")

## Recode variables for plotting.
ag1 = recode(ag$Group.1,"+" <- c(1),"-" <- c(-1))
ag2 = recode(ag$Group.2,"+" <- c(1),"-" <- c(-1))
ag3 = recode(ag$Group.3,"+" <- c(1),"-" <- c(-1))
ag12 = paste(ag1,ag2,sep="")
ag13 = paste(ag1,ag3,sep="")
ag23 = paste(ag2,ag3,sep="")
dfag = data.frame(ag$x,ag$Group.1,ag$Group.2,ag$Group.3,ag12,ag13,ag23)

## Generate the block plot for factor 1.
boxplot(dfag$ag.x ~ dfag$ag23, medlty="blank", boxwex=.5,
        ylab="Light Intensity",xlab="Factor Levels of X2,X3",
        main="Primary Factor X1", cex.main=1)
## Add points for the effects.
points(dfag$ag23[dfag$ag.Group.1==1],dfag$ag.x[dfag$ag.Group.1==1],
       pch=19,col="blue")
points(dfag$ag23[dfag$ag.Group.1==-1],dfag$ag.x[dfag$ag.Group.1==-1],
       col="blue")
## Add legend.
legend(3.25,350,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X1 Level", cex=.7, horiz=TRUE)

## Generate the block plot for factor 2.
boxplot(dfag$ag.x ~ dfag$ag13, medlty="blank", boxwex=.5,
        ylab="Sensitivity",xlab="Factor Levels of X1 X3",
        main="Primary Factor X2", cex.main=1)
## Add points for the effect means.
points(dfag$ag13[dfag$ag.Group.2==1],dfag$ag.x[dfag$ag.Group.2==1],
       pch=19,col="blue")
points(dfag$ag13[dfag$ag.Group.2==-1],dfag$ag.x[dfag$ag.Group.2==-1],
       col="blue")
## Add legend.
legend(.5,350,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X2 Level", cex=.7, horiz=TRUE)

## Generate the block plot for factor 3.
boxplot(dfag$ag.x ~ dfag$ag12, medlty="blank", boxwex=.5, 
        ylab="Sensitivity",xlab="Factor Levels of X1 X2",
        main="Primary Factor X3", cex.main=1)
## Add points for the effects.
points(dfag$ag12[dfag$ag.Group.3==1],dfag$ag.x[dfag$ag.Group.3==1],
       pch=19,col="blue")
points(dfag$ag12[dfag$ag.Group.3==-1],dfag$ag.x[dfag$ag.Group.3==-1],
       col="blue")
## Add legend.
legend(0.5,350,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X3 Level", cex=.7, horiz=TRUE)

## Generate level means for factor 4.
ag = aggregate(x=df2$y,by=list(df2$fx4,df2$fx1,df2$fx2),FUN="mean")

## Recode variables for plotting.
ag1 = recode(ag$Group.2,"+" <- c(1),"-" <- c(-1))
ag2 = recode(ag$Group.3,"+" <- c(1),"-" <- c(-1))
ag12 = paste(ag1,ag2,sep="")
dfag = data.frame(ag$x,ag$Group.1,ag12)

## Generate the block plot for factor 4.
boxplot(dfag$ag.x ~ dfag$ag12, medlty="blank", boxwex=.5,
        ylab="Light Intensity",xlab="Factor Levels of X1,X2",
        main="Primary Factor X4", cex.main=1)
## Add points for the effects.
points(dfag$ag12[dfag$ag.Group.1==1],dfag$ag.x[dfag$ag.Group.1==1],
       pch=19,col="blue")
points(dfag$ag12[dfag$ag.Group.1==-1],dfag$ag.x[dfag$ag.Group.1==-1],
       col="blue")
## Add legend.
legend(.5,220,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X4 Level", cex=.7, horiz=TRUE)

## Generate level means for factor 5.
ag = aggregate(x=df2$y,by=list(df2$fx5,df2$fx1,df2$fx2),FUN="mean")

## Recode variables for plotting.
ag1 = recode(ag$Group.2,"+" <- c(1),"-" <- c(-1))
ag2 = recode(ag$Group.3,"+" <- c(1),"-" <- c(-1))
ag12 = paste(ag1,ag2,sep="")
dfag = data.frame(ag$x,ag$Group.1,ag12)

## Generate the block plot for factor 5.
boxplot(dfag$ag.x ~ dfag$ag12, medlty="blank", boxwex=.5,
        ylab="Light Intensity",xlab="Factor Levels of X1,X2",
        main="Primary Factor X5", cex.main=1)
## Add points for the effects.
points(dfag$ag12[dfag$ag.Group.1==1],dfag$ag.x[dfag$ag.Group.1==1],
       pch=19,col="blue")
points(dfag$ag12[dfag$ag.Group.1==-1],dfag$ag.x[dfag$ag.Group.1==-1],
       col="blue")
## Add legend.
legend(.5,225,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X5 Level", cex=.7, horiz=TRUE)

## Generate level means for factor 6.
ag = aggregate(x=df2$y,by=list(df2$fx6,df2$fx1,df2$fx2),FUN="mean")

## Recode variables for plotting.
ag1 = recode(ag$Group.2,"+" <- c(1),"-" <- c(-1))
ag2 = recode(ag$Group.3,"+" <- c(1),"-" <- c(-1))
ag12 = paste(ag1,ag2,sep="")
dfag = data.frame(ag$x,ag$Group.1,ag12)

## Generate the block plot for factor 6.
boxplot(dfag$ag.x ~ dfag$ag12, medlty="blank", boxwex=.5,
        ylab="Light Intensity",xlab="Factor Levels of X1,X2",
        main="Primary Factor X6", cex.main=1)
## Add points for the effects.
points(dfag$ag12[dfag$ag.Group.1==1],dfag$ag.x[dfag$ag.Group.1==1],
       pch=19,col="blue")
points(dfag$ag12[dfag$ag.Group.1==-1],dfag$ag.x[dfag$ag.Group.1==-1],
       col="blue")
## Add legend.
legend(.5,225,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X6 Level", cex=.7, horiz=TRUE)

## Generate level means for factor 7.
ag = aggregate(x=df2$y,by=list(df2$fx7,df2$fx1,df2$fx2),FUN="mean")

## Recode variables for plotting.
ag1 = recode(ag$Group.2,"+" <- c(1),"-" <- c(-1))
ag2 = recode(ag$Group.3,"+" <- c(1),"-" <- c(-1))
ag12 = paste(ag1,ag2,sep="")
dfag = data.frame(ag$x,ag$Group.1,ag12)

## Generate the block plot for factor 7.
boxplot(dfag$ag.x ~ dfag$ag12, medlty="blank", boxwex=.5,
        ylab="Light Intensity",xlab="Factor Levels of X1,X2",
        main="Primary Factor X7", cex.main=1)
## Add points for the effects.
points(dfag$ag12[dfag$ag.Group.1==1],dfag$ag.x[dfag$ag.Group.1==1],
       pch=19,col="blue")
points(dfag$ag12[dfag$ag.Group.1==-1],dfag$ag.x[dfag$ag.Group.1==-1],
       col="blue")
## Add legend.
legend(.5,350,c("+","-"),pch=c(19,1), col="blue", bty="o",
       x.intersp=.75, title="X7 Level", cex=.7, horiz=TRUE)
par(mfrow=c(1,1))


## Generate Youden plot.

## Generate averages for each factor and level.
q1 = aggregate(x=dfip$y,by=list(dfip$fx1),FUN="mean")
qt1 = t(q1$x)
q2 = aggregate(x=dfip$y,by=list(dfip$fx2),FUN="mean")
qt2 = t(q2$x)
q3 = aggregate(x=dfip$y,by=list(dfip$fx3),FUN="mean")
qt3 = t(q3$x)
q4 = aggregate(x=dfip$y,by=list(dfip$fx4),FUN="mean")
qt4 = t(q4$x)
q5 = aggregate(x=dfip$y,by=list(dfip$fx5),FUN="mean")
qt5 = t(q5$x)
q6 = aggregate(x=dfip$y,by=list(dfip$fx6),FUN="mean")
qt6 = t(q6$x)
q7 = aggregate(x=dfip$y,by=list(dfip$fx7),FUN="mean")
qt7 = t(q7$x)
q12 = aggregate(x=dfip$y,by=list(dfip$fx12),FUN="mean")
qt12 = t(q12$x)
q13 = aggregate(x=dfip$y,by=list(dfip$fx13),FUN="mean")
qt13 = t(q13$x)
q14 = aggregate(x=dfip$y,by=list(dfip$fx14),FUN="mean")
qt14 = t(q14$x)
q15 = aggregate(x=dfip$y,by=list(dfip$fx15),FUN="mean")
qt15 = t(q15$x)
q16 = aggregate(x=dfip$y,by=list(dfip$fx16),FUN="mean")
qt16 = t(q16$x)
q17 = aggregate(x=dfip$y,by=list(dfip$fx17),FUN="mean")
qt17 = t(q17$x)
q24 = aggregate(x=dfip$y,by=list(dfip$fx24),FUN="mean")
qt24 = t(q24$x)
q124 = aggregate(x=dfip$y,by=list(dfip$fx124),FUN="mean")
qt124 = t(q124$x)

yp = rbind(qt1,qt2,qt3,qt4,qt5,qt6,qt7,
           qt12,qt13,qt14,qt15,qt16,qt17,qt24,qt124)

## Generate names for effect estimates.
z = lm(y ~ x1 + x2 + x3 + x4 + x5 + x6 + x7 +
           x12 + x13 + x14 + x15 + x16 + x17 + x24 + x124)
zz = summary(z)
effects = coef(z)[-1]*2

## Generate Youden plot.
plot(yp[,1],yp[,2], xlim=c(70,155), ylim=c(70,155),
     xlab="Average Response for -1 Settings",
     ylab="Average Response for +1 Settings",
     main="Youden Plot for Sonoluminescense Data")
text(yp[,1],yp[,2],labels=names(effects),pos=4,cex=.75)
abline(h=ybar)
abline(v=ybar)


## Save effects in decreasing order.
torder = zz$coefficients[order(abs(zz$coefficients[,1]),decreasing=TRUE),]
torder[,1]

#> (Intercept)          x2          x7         x13          x1          x3 
#>   110.60625   -39.30625   -39.05625    35.00625    33.10625    31.90625 
#>         x17         x12         x16         x14          x6          x5 
#>   -31.73125   -29.78125    -8.16875    -5.24375    -4.51875     3.74375 
#>        x124          x4         x24         x15 
#>     2.91875     1.85625     0.84375    -0.28125 

yvar = torder[-1,1]*2
lvar16 = rownames(torder)
lvar = lvar16[-1]
xvar = c(1:length(lvar))

## Plot absolute values of effects in decreasing order.
plot(xvar,abs(yvar), xlim=c(1,16), 
     main = "Sonoluminescent Light Intensity",
     ylab="|Effect|", xlab="", xaxt="n")
text(xvar,abs(yvar), labels=lvar, pos=4, cex=.8)


## Generate half-normal probability plot of effect estimates.
library(faraway)
halfnorm(effects,nlab=length(effects), cex=.8,
         labs=names(effects),
         ylab="Ordered |Effects|",
         main="Half-Normal Probability Plot of Sonoluminescent Data")


## Compute the residual standard deviation for cumulative
## models (mean plus cumulative terms).
z = lm(y ~ 1)
ese = summary(z)$sigma

z = update(z, . ~ . + x2)
se1 = summary(z)$sigma

z = update(z, . ~ . + x7)
se2 = summary(z)$sigma

z = update(z, . ~ . + x13)
se3 = summary(z)$sigma

z = update(z, . ~ . + x1)
se4 = summary(z)$sigma

z = update(z, . ~ . + x3)
se5 = summary(z)$sigma

z = update(z, . ~ . + x17)
se6 = summary(z)$sigma

z = update(z, . ~ . + x12)
se7 = summary(z)$sigma

z = update(z, . ~ . + x16)
se8 = summary(z)$sigma

z = update(z, . ~ . + x14)
se9 = summary(z)$sigma

z = update(z, . ~ . + x6)
se10 = summary(z)$sigma

z = update(z, . ~ . + x5)
se11 = summary(z)$sigma

z = update(z, . ~ . + x124)
se12 = summary(z)$sigma

z = update(z, . ~ . + x4)
se13 = summary(z)$sigma

z = update(z, . ~ . + x24)
se14 = summary(z)$sigma

z = update(z, . ~ . + x15)
se15 = summary(z)$sigma

Eff.SE = rbind(ese,se1,se2,se3,se4,se5,se6,se7,se8,se9,
               se10,se11,se12,se13,se14,se15)

## Plot residual standard deviation for cummulative models.
plot(Eff.SE, main = "Sonoluminescent Light Intensity",
     ylab="Cummulative Residual Standard Deviation", xlab="Additional Term", 
     xaxt="n")
text(c(1:length(Eff.SE)) ,Eff.SE, labels=lvar16, pos=4, cex=.8)

## Generate level means for plotting.
q = aggregate(x=dfip$y,by=list(dfip$fx2,dfip$fx7),FUN="mean")
qv1 = as.vector(q$Group.1,mode="numeric")-1
qv2 = as.vector(q$Group.2,mode="numeric")-1
qv1[qv1==0] = -1
qv2[qv2==0] = -1

## Contour plot y(x7),x(x2)
## Generate x and y data for plotting.
xord = seq(-2,2,by=.1)
yord = seq(-2,2,by=.1)

## Fit model with two factors, x2 and x7, and their interaction 
## for predicting the surface.
z = lm(y ~ 1 + x2 + x7 + x27)

## Generate predicted response surface and generate matrix of surface.
model = function (a, b){
  z$coefficients[1] +
  z$coefficients[2]*a +
  z$coefficients[3]*b +
  z$coefficients[4]*a*b}
pmatu = outer(xord,yord,model)

## Generate contour plot, add design points and labels.
contour(xord, yord, pmatu, nlevels=15, main="Contour Plot",
        xlab="x2", ylab="x7", col="blue")
points(qv1,qv2,pch=19)
text(c(qv1[1],qv1[3]),c(qv2[1],qv2[3]),labels=c(q$x[1],q$x[3]),pos=2)
text(c(qv1[2],qv1[4]),c(qv2[2],qv2[4]),labels=c(q$x[2],q$x[4]),pos=4)
lines(c(-1,1,1,-1,-1),c(-1,-1,1,1,-1))






#R commands:

## Read data.
fname = co2.dat
m = matrix(scan(fname,skip=2),ncol=4,byrow=T)

## Perform linear fit to detrend the data.
fit = lm(m[,1] ~ m[,2])

## Save residuals from fit as a time series object.
q = ts(fit$residuals,start=c(1974,5),frequency=12)

## Generate the seasonal subseries plot.
par(mfrow=c(1,1))
monthplot(q,phase=cycle(q), base=mean, ylab="CO2 Concentrations",
         main="Seasonal Subseries Plot of CO2 Concentrations",
         xlab="Month",
         labels=c("Jan","Feb","Mar","Apr","May","Jun",
                  "Jul","Aug","Sep","Oct","Nov","Dec"))

# #R commands and output:

## Read the data and save as a time series object.
table = matrix(scan("../res/g_series.dat", skip = 25), ncol=1, byrow=TRUE)
vec = ts(table)

## Load the necessary libraries.
library(stats)
installed.packages("lawstat")
library(lawstat)

## Plot the data print summary statistics.
par(mfrow=c(1,1), cex=1.2)
plot(1:length(vec),vec, type="o", pch=18, col="blue",
     xlab = "Observation", ylab="Series G")
print(summary(vec))

## Take natural log of original series and plot the results.
lvec = log(vec)
par(mfrow=c(1,1), cex=1.2)
plot(1:length(vec),lvec, type="o", pch=18, col="red",
	xlab = "Observation", ylab="ln(Series G)")

## Take first differences of transformed series to remove trend 
## and plot the transformed and differenced data.
fd = diff(lvec)
par(mfrow=c(1,1), cex=1.2)
plot(fd, type="o", pch=18,  col="darkblue",
	xlab = "Observation", ylab="Differenced ln(Series G)")

## Compute the autocorrelation of the transformed and differenced series.
ac <- acf(fd, type = c("correlation"), lag.max=36, main="Autocorrelation of Series G")

## Print ACF for first 36 lags.
round(c(ac$acf),4)

###>  [1]  1.0000  0.1998 -0.1201 -0.1508 -0.3221 -0.0840  0.0258 -0.1110 -0.3367
###> [10] -0.1156 -0.1093  0.2059  0.8414  0.2151 -0.1396 -0.1160 -0.2789 -0.0517
###> [19]  0.0125 -0.1144 -0.3372 -0.1074 -0.0752  0.1995  0.7369  0.1973 -0.1239
###> [28] -0.1027 -0.2110 -0.0654  0.0157 -0.1154 -0.2893 -0.1269 -0.0407  0.1474
###> [37]  0.6574

## Plot the ACF with 95 % confidence limits.
par(mfrow=c(1,1), cex=1.2)
plot(ac, ci=.95, ci.type="ma", main="ACF with 95 % Confidence Limits",
     ylim=c(-1,1))

##  Take seasonal differences of the transformed and differenced series.
sfd = diff(fd, lag=12)

## Plot final time series.
par(mfrow=c(1,1), cex=1.2)
plot(sfd, type="o", pch=18,  col="red", xlab = "Observation", 
     ylab="Seasonal and First Differenced ln(Series G)")

## Compute autocorrelation of final series.
sac = acf(sfd, type = c("correlation"), lag.max=36, 
           main="Autocorrelation of Series G")

## Plot the ACF of differenced series with 95 % confidence limits.
par(mfrow=c(1,1), cex=1.2)
plot(sac, ci=.95, ci.type="ma", main="ACF with 95 % Confidence Limits",
     ylim = c(-1,1))

## Fit a MA model to original series.  The arima function will 
## perform the necessary differences.
ma = arima(log(vec), order = c(0, 1, 1), 
            seasonal=list(order=c(0,1,1), period=12))
ma

###> Call:
###> arima(x = log(vec), order = c(0, 1, 1), seasonal = list(order = c(0, 1, 1), 
###>     period = 12))

###> Coefficients:
###>           ma1     sma1
###>       -0.4018  -0.5569
###> s.e.   0.0896   0.0731

###> sigma^2 estimated as 0.001348:  log likelihood = 244.7,  aic = -483.4

## Use the Box-Ljung test to determine if the residuals are 
## random up to 30 lags.
BT = Box.test(ma$residuals, lag=30, type = "Ljung-Box", fitdf=2)
BT

###>         Box-Ljung test
###> 
###> data:  ma$residuals 
###> X-squared = 29.4935, df = 30, p-value = 0.3878

## Although the output indicates that the degrees of freedom for 
## the test are 30, the p-value is based on df-fitdf = 30-2 = 28.
1-pchisq(29.4935,28)

###> [1] 0.3878282

## Determine critical region.
qchisq(0.95,28)

###> [1] 41.33714

## Generate predictions of 12 future values.
p = predict(ma,12)

## Compute 90% confidence intervals for each prediction
## and convert back to original units.
L90 = exp(p$pred - 1.645*p$se)
U90 = exp(p$pred + 1.645*p$se)

## Generate forecasts in original units.  To avoid under-predicting,
## the forecasts are adjusted to account for log transformation.
Forecast = exp(p$pred + ma$sigma2/2)

## Print the forecast results.
Period = c((length(vec)+1):(length(vec)+12))
df = data.frame(Period,L90,Forecast,U90)
print(df,row.names=FALSE)

###>   Period      L90 Forecast      U90
###>      145 424.0234 450.7261 478.4649
###>      146 396.7861 426.0042 456.7577
###>      147 442.5731 479.3298 518.4399
###>      148 451.3902 492.7365 537.1454
###>      149 463.3034 509.3982 559.3245
###>      150 527.3754 583.7383 645.2544
###>      151 601.9371 670.4625 745.7830
###>      152 595.7602 667.5274 746.9323
###>      153 495.7137 558.5657 628.5389
###>      154 439.1900 497.5430 562.8899
###>      155 377.7598 430.1618 489.1730
###>      156 417.3149 477.5643 545.7760

## Plot last 36 observations and the predictions with confidence limits.
par(mfrow=c(1,1), cex=1.2)
plot(c(108:144),table[108:144],xlim=c(108,160),ylim=c(300,800), type="o",
     ylab="Series G", xlab="Observation", col="black",
     main="12 Forecasts and 90% Confidence Intervals")
points(Forecast, pch=16, col="blue")
lines(c(145:156), L90, col="red")
lines(c(145:156), U90, col="red")


#R commands and output:

## Read the data and save some variables as factors.
m = read.table("monitor-6.6.1.1.dat",skip=4)
cassette = as.factor(m[,1])
wafer = as.factor(m[,2])
site = as.factor(m[,3])
raw = m[,4]
order = m[,5]


## Generate a 4-plot of the data.
library(Hmisc)
par(mfrow=c(2,2))
plot(raw,ylab="Raw Line Width",type="l")
plot(Lag(raw,1),raw,ylab="Raw Line Width",xlab="lag(Raw Line Width)")
hist(raw,main="",xlab="Raw Line Width")
qqnorm(raw,main="")
par(mfrow=c(1,1))


## Generate a run-order plot of the data.
plot(raw,ylab="Raw Line Width",xlab="Sequence",type="l")


## Generate a numerical Summary.

## Compute summary statistics.
ybar = round(mean(raw),5)
std = round(sd(raw),5)
n = round(length(raw),0)
stderr = round(std/sqrt(n),5)
v = round(var(raw),5)

# Compute the five-number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(raw)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(raw)-min(raw)),5)

## Compute the inter-quartile range.
iqry = round(IQR(raw),5)

## Compute the lag 1 autocorrelation.
z = acf(raw,plot=FALSE)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")

data.frame(Statistics)

###>                         Statistics
###> Number of Observations   450.00000
###> Mean                       2.53228
###> Std. Dev.                  0.69376
###> Std. Dev. of Mean          0.03270
###> Variance                   0.48130
###> Range                      4.42212
###> Lower Hinge                2.04814
###> Upper Hinge                2.97195
###> Inter-Quartile Range       0.91928
###> Autocorrelation            0.60726


## Generate a scatter plot of width versus cassette.
plot(m[,1], raw, xlab="Cassette", ylab="Raw Line Width")


## Generate a box plot of width versus cassette.
boxplot(raw ~ cassette, xlab="Cassette", ylab="Raw Line Width")


## Generate a scatter plot of width versus wafer.
plot(m[,2], raw, xlab="Wafer", ylab="Raw Line Width", xlim=c(0,4),
     xaxt="n")
axis(1,at=c(0:4),labels=c("","1","2","3",""))


## Generate a box plot of width versus wafer.
boxplot(raw ~ wafer, xlab="Wafer", ylab="Raw Line Width")


## Generate a scatter plot of width versus site.

## Save site as a numeric variable.
## The numbers 1-5 in nsite correspond to levels: Bot Cen Lef Rgt Top.
nsite = as.numeric(site)
plot(nsite, raw, xlab="Site", ylab="Raw Line Width", xaxt="n")
axis(1,at=c(1:5),labels=c("Bottom","Center","Left","Right","Top"))


## Generate a box plot of width versus site.
boxplot(raw ~ site, xlab="Site", ylab="Raw Line Width", xaxt="n")
axis(1,at=c(1:5),labels=c("Bottom","Center","Left","Right","Top"))


## Generate a Dex mean plot.

## Restructure data so that factors are in a single column.
## Save re-coded version of the factor levels for DEX mean plot.
tempxc = round(m[,1]/6,2) + 1
dm1 = cbind(raw,tempxc)
tempxc = m[,2] + 8
dm2 = cbind(raw,tempxc)
tempxc = nsite + 13
dm3 = cbind(raw,tempxc)
dm4 = rbind(dm1,dm2,dm3)

## Generate factor ID variable.
n = length(raw)
varind = c(rep("Cassette",n),rep("Wafer",n),rep("Site",n))
varind = as.factor(varind)

## Save restructured data in a data frame.
df = data.frame(dm4,varind)

## Generate plot.
q = aggregate(x=df$raw,by=list(df$varind,df$tempxc),FUN="mean")
plot(q$Group.2, q$x, ylab="Raw Line Width", xlab="Factors", 
     pch=19, xaxt="n", ylim=c(1,5))
xpos = c(3.5,10,16)
xlabel = c("Cassette","Wafer","Site")
axis(side=1,at=xpos,labels=xlabel)
abline(h=mean(raw))


## Generate a Dex sd plot.
q = aggregate(x=df$raw,by=list(df$varind,df$tempxc),FUN="sd")
plot(q$Group.2, q$x, ylab="Raw Line Width", xlab="Factors", 
     pch=19, xaxt="n", ylim=c(.4,.8))
xpos = c(3.5,10,16)
xlabel = c("Cassette","Wafer","Site")
axis(side=1,at=xpos,labels=xlabel)
abline(h=sd(raw))


## Generate moving average control chart.
raw.mr = abs(raw - Lag(raw))
raw.ma = (raw + Lag(raw))/2

center = mean(raw.ma[2:length(raw)])
mn.mr  = mean(raw.mr[2:length(raw)])
d2 = 1.128
lcl = center - 3*mn.mr/d2
ucl = center + 3*mn.mr/d2

## Generate plot.
plot(raw.ma, ylim=c(1,5), type="l", ylab="Moving average of line width")
abline(h=center)
abline(h=lcl)
abline(h=ucl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=center,"Center")


## Generate moving range control chart.
lcl = mn.mr - 3*mn.mr/d2
ucl = mn.mr + 3*mn.mr/d2
plot(raw.mr, type="l", ylab="Moving range of line width")
abline(h=mn.mr)
abline(h=ucl)
abline(h=max(0,lcl))
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=max(0,lcl),"LCL")
mtext(side=4,at=mn.mr,"Center")


## Generate mean control chart (wafers).

## Compute averages and standard deviations for each cassette and wafer.
qmn = aggregate(x=raw,by=list(wafer,cassette),FUN="mean")
qsd = aggregate(x=raw,by=list(wafer,cassette),FUN="sd")

## Compute center line and control limits.
center = mean(qmn$x)
sbar = mean(qsd$x)
n = 5
c4 = 4*(n-1)/(4*n-3)
A3 = 3/(c4*sqrt(n))
ucl = center + A3*sbar
lcl = center - A3*sbar

## Generate chart.
plot(qmn$x, type="o", pch=16, ylab="Mean of line width", xlab="Wafer")
abline(h=center)
abline(h=ucl)
abline(h=lcl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=center,"Center")


## Generate SD control chart (wafers).

## Compute center line and upper control limit and generate chart.
ucl = sbar + 3*(sbar/c4)*sqrt(1-c4**2)
plot(qsd$x, type="o", pch=16, ylim=c(.1,.9), ylab="SD of line width",
     xlab="Wafer")
abline(h=sbar)
abline(h=ucl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=sbar,"Center")


## Generate mean control chart (cassettes).

## Compute averages and standard deviations for each cassette.
qmn = aggregate(x=raw,by=list(cassette),FUN="mean")
qsd = aggregate(x=raw,by=list(cassette),FUN="sd")

## Compute center line and control limits.
center = mean(qmn$x)
sbar = mean(qsd$x)
n = 15
c4 = 4*(n-1)/(4*n-3)
A3 = 3/(c4*sqrt(n))
ucl = center + A3*sbar
lcl = center - A3*sbar

## Generate chart.
plot(qmn$x, type="o", pch=16, ylab="Mean of line width", xlab="Cassette",
     ylim=c(1.5,4.5))
abline(h=center)
abline(h=ucl)
abline(h=lcl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=center,"Center")


## Generate SD control chart (cassettes).

## Compute center line and control limits and generate chart.
ucl = sbar + 3*(sbar/c4)*sqrt(1-c4**2)
lcl = sbar - 3*(sbar/c4)*sqrt(1-c4**2)
plot(qsd$x, type="o", pch=16, ylab="SD of line width", ylim=c(.1,.9),
     xlab="Cassette")
abline(h=sbar)
abline(h=ucl)
abline(h=lcl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=sbar,"Center")

## Generate the component of variance table.

## Attach necessary libraries.
library("nlme")
library("ape")

## Create data frame.
df = data.frame(raw,cassette,wafer)

## Fit the random effects model and print variance components.
z = lme(raw ~ 1, random=~1|cassette/wafer, data=df)
varcomp(z)

###>   cassette      wafer     Within 
###> 0.26452145 0.04997089 0.17549617 
###> attr(,"class")
###> [1] "varcomp"

## The "Within" component represents site variation.


## Generate mean squares.
aov(raw ~ cassette + wafer/cassette - wafer)

###> Call:
###>    aov(formula = raw ~ cassette + wafer/cassette - wafer)

###> Terms:
###>                  cassette cassette:wafer Residuals
###> Sum of Squares  127.40293       25.52089  63.17865
###> Deg. of Freedom        29             60       360

###> Residual standard error: 0.4189227 
###> Estimated effects may be unbalanced


## Generate a mean control chart using lot-to-lot variation.

## Compute averages and standard deviations for each cassette.
qmn = aggregate(x=raw,by=list(cassette),FUN="mean")
qsd = aggregate(x=raw,by=list(cassette),FUN="sd")
ql = aggregate(x=raw,by=list(cassette),FUN="length")

## Compute center line and within-lot control limits.
center = mean(qmn$x)
sbar = mean(qsd$x)
n = ql$x[1]
c4 = 4*(n-1)/(4*n-3)
A3 = 3/(c4*sqrt(n))
ucl = center + A3*sbar
lcl = center - A3*sbar

## Compute between-lot control limits.
sdybar = sd(qmn$x)
ll = center - 3*sdybar
ul = center + 3*sdybar

## Generate chart.
plot(qmn$x, type="o", pch=16, ylim=c(0,5),
     ylab="Mean of Line Width", xlab="Cassette")
abline(h=center)
abline(h=ucl)
abline(h=lcl)
abline(h=ll)
abline(h=ul)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=ll,"Lot-to-Lot")
mtext(side=4,at=ul,"Lot-to-Lot")
#R commands and output:

## Read the data and save some variables as factors.
m = read.table("monitor-6.6.1.1.dat",skip=4)
cassette = as.factor(m[,1])
wafer = as.factor(m[,2])
site = as.factor(m[,3])
raw = m[,4]
order = m[,5]

## Moving average control chart.
library(Hmisc)
raw.mr = abs(raw - Lag(raw))
raw.ma = (raw + Lag(raw))/2

center = mean(raw.ma[2:length(raw)])
mn.mr  = mean(raw.mr[2:length(raw)])
d2 = 1.128
lcl = center - 3*mn.mr/d2
ucl = center + 3*mn.mr/d2

plot(raw.ma, ylim=c(1,5), type="l", ylab="Moving average of line width")
abline(h=center)
abline(h=lcl)
abline(h=ucl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=center,"Center")

## Moving range control chart.
lcl = mn.mr - 3*mn.mr/d2
ucl = mn.mr + 3*mn.mr/d2
plot(raw.mr, type="l", ylab="Moving range of line width")
abline(h=mn.mr)
abline(h=ucl)
abline(h=max(0,lcl))
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=max(0,lcl),"LCL")
mtext(side=4,at=mn.mr,"Center")


## Mean control chart for wafers.
## Compute averages and standard deviations for each cassette and wafer.
qmn = aggregate(x=raw,by=list(wafer,cassette),FUN="mean")
qsd = aggregate(x=raw,by=list(wafer,cassette),FUN="sd")

## Compute center line and control limits.
center = mean(qmn$x)
sbar = mean(qsd$x)
n = 5
c4 = 4*(n-1)/(4*n-3)
A3 = 3/(c4*sqrt(n))
ucl = center + A3*sbar
lcl = center - A3*sbar

## Generate control chart.
plot(qmn$x, type="o", pch=16, ylab="Mean of line width", xlab="Wafer")
abline(h=center)
abline(h=ucl)
abline(h=lcl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=center,"Center")

## SD control chart for wafers.
## Compute center line and upper control limit and generate chart.
ucl = sbar + 3*(sbar/c4)*sqrt(1-c4**2)
plot(qsd$x, type="o", pch=16, ylim=c(.1,.9), ylab="SD of line width",
     xlab="Wafer")
abline(h=sbar)
abline(h=ucl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=sbar,"Center")

## Mean control chart for cassettes.
## Compute averages and standard deviations for each cassette.
qmn = aggregate(x=raw,by=list(cassette),FUN="mean")
qsd = aggregate(x=raw,by=list(cassette),FUN="sd")

## Compute center line and control limits.
center = mean(qmn$x)
sbar = mean(qsd$x)
n = 15
c4 = 4*(n-1)/(4*n-3)
A3 = 3/(c4*sqrt(n))
ucl = center + A3*sbar
lcl = center - A3*sbar

## Generate control chart.
plot(qmn$x, type="o", pch=16, ylab="Mean of line width", xlab="Cassette",
     ylim=c(1.5,4.5))
abline(h=center)
abline(h=ucl)
abline(h=lcl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=center,"Center")

## SD control chart for cassettes.
## Compute center line and control limits and generate chart.
ucl = sbar + 3*(sbar/c4)*sqrt(1-c4**2)
lcl = sbar - 3*(sbar/c4)*sqrt(1-c4**2)
plot(qsd$x, type="o", pch=16, ylab="SD of line width", ylim=c(.1,.9),
     xlab="Cassette")
abline(h=sbar)
abline(h=ucl)
abline(h=lcl)
mtext(side=4,at=ucl,"UCL")
mtext(side=4,at=lcl,"LCL")
mtext(side=4,at=sbar,"Center")

## Compute component of variance.
## Attach necessary libraries.
library("nlme")
library("ape")

## Create new data frame.
df = data.frame(raw,cassette,wafer)

## Fit the random effects model and print variance components.
z = lme(raw ~ 1, random=~1|cassette/wafer, data=df)
varcomp(z)

###>   cassette      wafer     Within 
###> 0.26452145 0.04997089 0.17549617 
###> attr(,"class")
###> [1] "varcomp"

## Analysis of variance - use sums of squares and degrees 
## of freedom to manually compute variance components.
aov(raw ~ cassette + wafer/cassette - wafer)

###> Call:
###>    aov(formula = raw ~ cassette + wafer/cassette - wafer)

###> Terms:
###>                  cassette cassette:wafer Residuals
###> Sum of Squares  127.40293       25.52089  63.17865
###> Deg. of Freedom        29             60       360

###> Residual standard error: 0.4189227 
###> Estimated effects may be unbalanced

## Compute expected mean squares and variance components
## using varcompci package.
## Attach library varcompci.
library(varcompci)
X <- data.frame(c=df$cassette,w=df$wafer)
y <- raw
totvar = c("c","w")
Matrix = matrix(cbind(c(1,0),c(1,1)),ncol=2)
response = "y"
dsn = "X"
x <- varcompci(dsn=dsn, response=response, totvar=totvar, Matrix=Matrix)
summary(x)

###> Expected Mean Square
###>       EMS                                
###> c     "var(Resid) + 5var(c:w) + 15var(c)"
###> c:w   "var(Resid) + 5var(c:w)"           
###> resid "var(Resid)"                       
###> 
###> Anova of mixed model
###>        df        SS      MS        F Pval
###> c      29 127.40293 4.39320 10.32849    0
###> c:w    60  25.52089 0.42535  2.42369    0
###> resid 360  63.17865 0.17550              
###> 
###> Random and Fixed Mean Square
###>        Mean Sq 
###> c     4.3932045
###> c:w   0.4253482
###> resid 0.1754962
###> 
###> Covariance Paramater Estimate
###>       Covariance paramater
###> c               0.26452376
###> c:w             0.04997039
###> resid           0.17549624
###> 
###> Fit Statistics
###> AIC (smaller is better)  
###>                 575.5681 
###> 
###> BIC (smaller is better)  
###>                 949.5097 
###> 
###> Confidence Interval of variance components
###>       Method      LB Estimate      UB
###> c      TBGJL 0.15649  0.26452 0.50078
###> c:w    TBGJL  0.0254  0.04997 0.09113
###> resid  Exact 0.15244   0.1755 0.20424

#R commands and output:

## Read data and save variable as a time series object.
size = ts(scan("monitor-6.6.2.1.dat"))

## Generate run-order plot.
plot(size, ylab="Size", xlab="Sequence", main="Run-Order Plot")

## Generate autocorrelation plot with 95 % confidence bands.
acf(size, type = c("correlation"), lag.max=50, 
    main="Autocorrelation of Size", ylim=c(-0.5,1))

## Take first differences.
dsize = diff(size)
plot(dsize, ylab="Size", xlab="Sequence", 
     main="Run-Order Plot of Differenced Data")

## Generate autocorrelation plot of first differenced data.
acf(dsize, type = c("correlation"), lag.max=50, 
    main="Autocorrelation of Differenced Data With 95 % Confidence Bands", 
    ylim=c(-.5,1))

## Generate partial autocorrelation plot of first differenced data.
pacf(dsize, lag.max=50, 
     main="Partial Autocorrelation of Differenced Data",
     sub="95 % Confidence Bands")


## Fit the AR(2) model to differenced series.
ar2 = arima(dsize, order=c(2,0,0))
ar2

###> Call:
###> arima(x = dsize, order = c(2, 0, 0))

###> Coefficients:
###>           ar1      ar2  intercept
###>       -0.4064  -0.1649    -0.0050
###> s.e.   0.0419   0.0419     0.0119

###> sigma^2 estimated as 0.1956:  log likelihood = -336.55,  aic = 681.1

## Compute 95 % confidence intervals for each parameter.
lo = ar2$coef[1] - qnorm(.975)*sqrt(ar2$var.coef[1,1])
up = ar2$coef[1] + qnorm(.975)*sqrt(ar2$var.coef[1,1])
ar1_ci = c(lo,up)
names(ar1_ci) = c("ar1 LCL", "ar1 UCL")
ar1_ci

###>    ar1 LCL    ar1 UCL 
###> -0.4884159 -0.3243078

lo = ar2$coef[2] - qnorm(.975)*sqrt(ar2$var.coef[2,2])
up = ar2$coef[2] + qnorm(.975)*sqrt(ar2$var.coef[2,2])
ar2_ci = c(lo,up)
names(ar2_ci) = c("ar2 LCL", "ar2 UCL")
ar2_ci

###>         ar2         ar2 
###> -0.24693260 -0.08287961


## Fit MA(1) model to detrended size data.
ma <- arima(dsize, order = c(0, 0, 1), include.mean=TRUE)
ma

###> Call:
###> arima(x = dsize, order = c(0, 0, 1), include.mean = TRUE)

###> Coefficients:
###>           ma1  intercept
###>       -0.3921    -0.0051
###> s.e.   0.0366     0.0114

###> sigma^2 estimated as 0.1966:  log likelihood = -338,  aic = 681.99

## Compute 95 % confidence intervals for ma1.
lo = ma$coef[1] - qnorm(.975)*sqrt(ma$var.coef[1,1])
up = ma$coef[1] + qnorm(.975)*sqrt(ma$var.coef[1,1])
ma1_ci = c(lo,up)
names(ma1_ci) = c("ma1 LCL", "ma1 UCL")
ma1_ci

###>    ma1 LCL    ma1 UCL 
###> -0.4638111 -0.3204770


## Attach library Hmisc and generate a 4-plot of the residuals
## from the AR(2) model.
library(Hmisc)
par(mfrow=c(2,2))
plot(ar2$residuals,ylab="AR(2) Residuals",type="l")
plot(Lag(ar2$residuals,1),ar2$residuals,
     ylab="AR(2) Residuals",xlab="lag(AR(2) Residuals)")
hist(ar2$residuals,main="",xlab="AR(2) Residuals",breaks=20)
qqnorm(ar2$residuals,main="")
par(mfrow=c(1,1))


## Generate autocorrelation Plot of Residuals from ARIMA(2) Model
acf(ar2$residuals, lag.max=50, main="Residuals from the ARIMA(2,1,0) Model")


## Perform Ljung-Box Test for Randomness for the ARIMA(2,1,0) Model
Box.test(ar2$residuals, lag=24, type = "Ljung-Box")

###>         Box-Ljung test
###>
###> data:  ar2$residuals 
###> X-squared = 31.8409, df = 24, p-value = 0.131


## Generate a 4-plot of the residuals from the MA(1) model.
par(mfrow=c(2,2))
plot(ma$residuals,ylab="MA(1) Residuals",type="l")
plot(Lag(ma$residuals,1),ma$residuals,
     ylab="MA(1) Residuals",xlab="lag(MA(1) Residuals)")
hist(ma$residuals,main="",xlab="MA(1) Residuals",breaks=20)
qqnorm(ma$residuals,main="")
par(mfrow=c(1,1))


## Generate Autocorrelation Plot of Residuals from MA(1) Model
acf(ma$residuals, lag.max=50, main="Residuals from the MA(1) Model")


## Perform Ljung-Box Test for Randomness of the Residuals 
## for the MA(1) Model
Box.test(ma$residuals, lag=24, type = "Ljung-Box")

###>         Box-Ljung test
###>
###> data:  ma$residuals 
###> X-squared = 37.8865, df = 24, p-value = 0.03561
#R commands and output:

## Input constants.
d=55
v = 100
r = 1 + d/v

## Find the root of the function.
cnu = function(nu){pchisq(qchisq(.95,nu)/r,nu) - 0.01}
size = uniroot(cnu,c(1,200))
size$root

#> [1] 169.3335

## Generate table of sample sizes.
x=matrix(nrow=200, ncol=3)
for(nu in (1:200)){
bnu = qchisq(.95,nu)
bnu=bnu/r
cnu=pchisq(bnu,nu)
x[nu,1] = nu
x[nu,2] = bnu
x[nu,3] = cnu}
print(x[165:175,])

#>      nu      bnu         cnu
#> 165 165 126.4344 0.011366199
#> 166 166 127.1380 0.011035681
#> 167 167 127.8414 0.010714513
#> 168 168 128.5446 0.010402441
#> 169 169 129.2477 0.010099215
#> 170 170 129.9506 0.009804594
#> 171 171 130.6533 0.009518341
#> 172 172 131.3558 0.009240228
#> 173 173 132.0582 0.008970030
#> 174 174 132.7604 0.008707531
#> 175 175 133.4625 0.008452517#R commands and output:


## Initalize constants.
alpha=0.10
nd = 4
n = 20

## Define functions for upper and lower limits
## for a 90 % confidence interval.
fl = function(p){pbinom(nd-1,n,p) - (1-alpha/2)}
fu = function(p){pbinom(nd,n,p) - alpha/2}

## Find the roots of the functions.
pl = uniroot(fl,c(.01,.99))
pl$root

#> [1] 0.07134838

pu = uniroot(fu,c(.01,.99))
pu$root

#> [1] 0.4010294
#R commands and output:


## Compute the approximate and exact k2 factor.

## Compute the approximate k2 factor for a two-sided tolerance interval. 
## For this example, the standard deviation is computed fromt the sample,
## so the degrees of freedom are nu = N - 1.
N = 43
nu = N - 1
p = 0.90
g = 0.99
z2 = (qnorm((1+p)/2))**2
c2 = qchisq(1-g,nu)
k2 = sqrt(nu*(1 + 1/N)*z2/c2)
k2

###> [1] 2.217316


## Compute the exact k2 factor for a two-sided tolerance interval using 
## the K.factor function in the tolerance library
library(tolerance)
K2 = K.factor(n=N, f=nu, alpha=((1+p)/2), P=g, side=2, method="EXACT", m=100)
K2

###> [1] 2.210167


## "Direct" calculation of a tolerance interval.

## Read data and name variables.
m = read.table("../res/100ohm.dat")
colnames(m) = c("cr", "wafer", "mo", "day", "h", "min", "op", 
                 "hum", "probe", "temp", "y", "sw", "df")

## Attach tolerance library and call function.
library(tolerance)
normtol.int(m$y, alpha=0.01, P=.90, side=2)

#>   alpha   P    x.bar 2-sided.lower 2-sided.upper
#> 1  0.01 0.9 97.06984      97.00273      97.13695


## Calculate the k factor for a one-sided tolerance interval.

n = 43
p = 0.90
g = 0.99
nu = n-1
zp = qnorm(p)
zg = qnorm(g)
a = 1 - ((zg**2)/(2*nu))
b = zp**2 - (zg**2)/n
k1 = (zp + (zp**2 - a*b)**.5)/a
c(a,b,k1)

#> [1] 0.9355727 1.5165164 1.8751896


## Tolerance factor based on the non-central t distribution.

n = 43
p = .90
g = .99
f = n - 1
delta = qnorm(p)*sqrt(n)
k = qt(g,f,delta)/sqrt(n)
k

#> [1] 1.873954
#R commands and output:

## Set the proportions of interest.
p = c(0.120, 0.153, 0.140, 0.210, 0.127)
N = length(p)
value = critical.range = c()

## Compute critical values.
for (i in 1:(N-1))
   { for (j in (i+1):N)
    {
     value = c(value,(abs(p[i]-p[j])))
     critical.range = c(critical.range,
      sqrt(qchisq(.95,4))*sqrt(p[i]*(1-p[i])/300 + p[j]*(1-p[j])/300))
    }
   }

round(cbind(value,critical.range),3)

#>       value critical.range
#>  [1,] 0.033          0.086
#>  [2,] 0.020          0.085
#>  [3,] 0.090          0.093
#>  [4,] 0.007          0.083
#>  [5,] 0.013          0.089
#>  [6,] 0.057          0.097
#>  [7,] 0.026          0.087
#>  [8,] 0.070          0.095
#>  [9,] 0.013          0.086
#> [10,] 0.083          0.094#Functions for computing PDF values and CDF values

## There are two ways to specify the Weibull
## distribution function.

## (1)
Y = pweibull(800*5, 1.5, 8000)

#> [1] 0.2978115

## (2)

Y = pweibull((800*5)/8000,shape=1.5)  

#> [1] 0.2978115#Exponential distribution

## Evaluate the PDF at 100 hours for an exponential with lambda = 0.01.
dexp(100,0.01)

#> [1] 0.003678794

## Evaluate the CDF at 100 hours for an exponential with lambda = 0.01.
pexp(100,0.01)

#> [1] 0.6321206

## Generate an exponential probability plot, normalized so that a
## perfect exponential fit is a diagonal line with slope 1.

## Generate 100 random exponential values using lambda = 0.01.
Y = rexp(100,0.01)
Y

## Generate theoretical quantiles of the exponential distribution.
library(MASS)
p = fitdistr(Y,"exponential")
simdata <- qexp(ppoints(length(Y)), rate=p$estimate)

## Generate probability plot.
qqplot(simdata, Y, xlab="Theoretical Quantiles")
abline(a=0, b=1, lty=3)
#Weibull distribution

## Evaluate the PDF a Weibull distribution with 
## T=1000, gamma=1.5, and alpha=5000.
T = 1000
gamma = 1.5 
alpha = 5000
dweibull(T, gamma, alpha)

###> [1] 0.0001226851


## Evaluate the CDF a Weibull distribution with T=1000, 
## gamma=1.5, and alpha=5000.
pweibull(T, gamma, alpha)

###> [1] 0.08555936

## Generate 100 random numbers from a Weibull with shape parameter 
## gamma=1.5 and characteristic life alpha=5000.
sample = rweibull(100, 1.5, 5000)


## The Weibull probability plot is not available directly in R. However, 
## the plot can be created using the formula -ln(1 - p) for the percentiles
## and plotting on a log-log scale.

## Generate a Weibull probability plot for the data generated.
p = ppoints(sort(sample), a=0.3)
plot(sort(sample), -log(1-p), log="xy", type="o", col="blue",
     xlab="Time", ylab="ln(1/(1-F(t)))",
     main = "Weibull Q-Q Plot")
#Extreme value distribution

## Define constants.
BET = 0.5
M = log(200000) 


## Load gamlss.dist package.
require(gamlss.dist)


## Calculate PDF and CDF values of the extreme value distribution
## corresponding to the points 5, 8, 10, 12, 12.8. 
X = c(5, 8, 10, 12, 12.8)


## Calculate PDF values.
PD = dGU(X, mu=M, sigma=BET)
PD

#> [1] 1.101323e-06 4.442068e-04 2.396581e-02 6.830234e-01 2.468350e-01


## Calculate CDF values.
CD = pGU(X, mu=M, sigma=BET)
CD

#> [1] 5.506615e-07 2.221281e-04 1.205587e-02 4.842990e-01 9.623731e-01


## Generate 100 random numbers from the extreme value distribution.
## (The type 1 extreme value distribution is sometimes called the
## Gumbel distribution.)
SAM= rGU(100, mu=M, sigma=BET)


## Load lattice package.
require(lattice)

## Generate extreme value probability plot.
qqmath (SAM, distribution = function(p) qGU(p),
        ylab="Sample Data", xlab="Theoretical Minimum")
#Lognormal distribution

## Define constants.
T = 5000
sigma = 0.5
T50 = 20000


## Find PDF values.
PDF = dlnorm(T,sdlog=sigma, meanlog=log(T50))
PDF

#> [1] 3.417475e-06


## Find CDF values.
CDF = plnorm(T,sdlog=sigma, meanlog=log(T50))
CDF

#> [1] 0.002780618


## Find failure rate.
HAZ = dlnorm(T, sdlog=sigma, 
      meanlog=log(T50))/(1-plnorm(T,sdlog=sigma, meanlog=log(T50)))
HAZ

#> [1] 3.427004e-06


## Generate 100 lognormal random numbers for probability plot.
sample=rlnorm(100, meanlog=log(20000), sdlog=0.5)


## Generate lognormal probability plot.
require(lattice)
qqmath(sample, distribution=function(p) qlnorm(p,sdlog=0.5),
       ylab="TIME", xlab="EXPECTED (NORMALIZED) VALUES" ,type="l")


## Generate lognormal probability plot when sigma is estimated from data.
logsamp = log(sample)
SD.est = sd(logsamp)
qqmath(sample, distribution=function(p) qlnorm(p,sdlog=SD.est),
       ylab="TIME", xlab="EXPECTED (NORMALIZED) VALUES", type="l")#Gamma distribution

## Define constants.
## Shape = alpha = a.
## Scale = beta (b = 1/beta).
t = 24
a = 2
beta = 30


## Calculate PDF value.
pdf1 = dgamma(t, shape=a, scale=beta)
pdf1

###> [1] 0.01198211


## Calculate CDF value.
cdf1 = pgamma(t, shape=a, scale=beta)
cdf1

###> [1] 0.1912079
  

## Calculate reliability.
REL = 1-cdf1
REL

###> [1] 0.8087921

## Calculate failure rate.
FR = pdf1/REL
FR

###> [1] 0.01481481
  

## Generate 100 Gamma random numbers.
data1 = rgamma(100, shape=a, scale=beta)


## Load lattice library for plotting.
require(lattice)


## Generate probability plot.
qqmath(data1,distribution=function(p) qgamma(p, shape=2),  
       ylab="TIME" ,xlab="EXPECTED (NORMALIZED) VALUES")


## The value of the shape parameter gamma can be 
## estimated with a method of moments estimator.
shape.est = (mean(data1)/sd(data1))^2
qqmath(data1, distribution=function(p) qgamma(p, shape=shape.est),  
       ylab="TIME" ,xlab="EXPECTED (NORMALIZED) VALUES")
# Birnbaum-Saunders distribution

##  Load VGAM package.
require(VGAM)

## Define constants gamma and mu.
mu = 5000
gamma = 2
t = 4000

## Compute the PDF at t=4000.
PDF = dbisa(t, shape=gamma, scale=mu)
PDF

#> [1] 4.986585e-05


## Compute the CDF.
CDF = pbisa(t, shape=gamma, scale=mu)
CDF

#> [1] 0.4554896


## Generate 100 random numbers from the Birnbaum-Saunders
## distribution.
data.bs= rbisa (100, shape=2, scale=5000)


## Load lattice package for probability plot.
require(lattice)

## Generate probability plot.
qqmath(data.bs, distribution=function(p) qbisa(p, shape=2),
       ylab="Time", xlab="Expected Value")


## Functions to estimate scale and shape parameters from data.
harmon=function(x) {1/(mean(1/x))}
scale.mm = function(y) {sqrt(mean(y)*harmon(y))}
shape.mm= function(y) {sqrt(2*sqrt(mean(y)/harmon(y))-1)}

## Calculate shape parameter.
shape.est=shape.mm(data.bs)
shape.est

#> [1] 2.109786

## Calculate scale parameter.
scale.mm(data.bs)

#> [1] 5593.329

## Generate probability plot.
qqmath(data.bs, distribution=function(p) qbisa(p, shape=shape.est))



#R commands and output:

## Set the reasonable MTBF, the low MTBF, and 
## calculate their ratio RT.
MTBF50 = 600
MTBF05 = 250
RT = MTBF50/MTBF05

## Find gamma prior parameter "a" so that the ratio
## qgamma(0.95,a,1)/qgamma(0.5,a,1) equals the RT

estimating_a = function(a)
{
 return(qgamma(0.95,a,1)/qgamma(0.5,a,1)-RT)
}
A = uniroot(estimating_a, c(0.001,500), tol = .Machine$double.eps)
a = A[1]$root
a

###> [1] 2.863055

## (3) Find gamma prior parameter b
b = 0.5*MTBF50*qgamma(0.5,a,1/2)
b

###> [1] 1522.506

## Check probabilities.
pgamma(.001667,shape=2.863,scale=1/1522.46)

###> [1] 0.5001232

pgamma(.004,shape=2.863,scale=1/1522.46) 

###> [1] 0.9499963#R commands and output:

## Load the package containing special survival analysis functions.
require(survival)

## Create survival object.
failures = c(55, 187, 216, 240, 244, 335, 361, 373, 375, 386)
y = Surv(c(failures, rep(500, 10)), c(rep(1, length(failures)), rep(0, 10)))

## Fit survival data.
ys = survfit(y ~ 1, type="kaplan-meier")
summary(ys)

#> Call: survfit(formula = y ~ 1, type = "kaplan-meier")
#> 
#>  time n.risk n.event survival std.err lower 95% CI upper 95% CI
#>    55     20       1     0.95  0.0487        0.859        1.000
#>   187     19       1     0.90  0.0671        0.778        1.000
#>   216     18       1     0.85  0.0798        0.707        1.000
#>   240     17       1     0.80  0.0894        0.643        0.996
#>   244     16       1     0.75  0.0968        0.582        0.966
#>   335     15       1     0.70  0.1025        0.525        0.933
#>   361     14       1     0.65  0.1067        0.471        0.897
#>   373     13       1     0.60  0.1095        0.420        0.858
#>   375     12       1     0.55  0.1112        0.370        0.818
#>   386     11       1     0.50  0.1118        0.323        0.775

## Generate Kaplan-Meier survival curve.
plot(ys, xlab="Hours", ylab="Survival Probability")

## Generate a Weibull probability plot.
p = ppoints(failures, a=0.3)
plot(failures, -log(1-p), log="xy", pch=19, col="red",
     xlab="Hours", ylab="Cumulative Hazard")

## Estimate parameters for Weibull distribution.
yw = survreg(y ~ 1, dist="weibull")
summary(yw)

#> Call:
#> survreg(formula = y ~ 1, dist = "weibull")
#>              Value Std. Error     z         p
#> (Intercept)  6.407      0.205 31.20 9.80e-214
#> Log(scale)  -0.546      0.292 -1.87  6.15e-02
#> 
#> Scale= 0.58 
#> 
#> Weibull distribution
#> Loglik(model)= -75.1   Loglik(intercept only)= -75.1
#> Number of Newton-Raphson Iterations: 5 
#> n= 20 

## Log-likelihood and Akaike's Information Criterion
signif(summary(yw)$loglik, 5)


#> [1] -75.122 -75.122

signif(extractAIC(yw), 5)

#> [1]   2.00 154.24

## Maximum likelihood estimates:
## For the Weibull model, survreg fits log(T) = log(eta) +
## (1/beta)*log(E), where E has an exponential distribution with mean 1
## eta = Characteristic life (Scale) 
## beta = Shape

etaHAT <- exp(coefficients(yw)[1])
betaHAT <- 1/yw$scale
signif(c(eta=etaHAT, beta=betaHAT), 6)

#> eta.(Intercept)            beta 
#>       606.00500         1.72563 

## Lifetime: expected value and standard deviation.
muHAT = etaHAT * gamma(1 + 1/betaHAT)
sigmaHAT = etaHAT * sqrt(gamma(1+2/betaHAT) - (gamma(1+1/betaHAT))^2)
names(muHAT) = names(sigmaHAT) = names(betaHAT) = names(etaHAT) = NULL
signif(c(mu=muHAT, sigma=sigmaHAT), 6)

#>      mu   sigma 
#> 540.175 322.647

## Probability density of fitted model.
curve(dweibull(x, shape=betaHAT, scale=etaHAT),
      from=0, to=muHAT+6*sigmaHAT, col="blue",
      xlab="Hours", ylab="Probability Density")

## Weibull versus lognormal models.
yl = survreg(y ~ 1, dist="lognormal")
signif(c(lognormalAIC=extractAIC(yl)[2], weibullAIC=extractAIC(yw)[2]), 5)

#> lognormalAIC   weibullAIC 
#>       154.33       154.24
#R commands and output:

## Evaluate a lognormal CDF at time T.

T = 100000
T50 = 507383 
sigma = 0.74

y = plnorm(T/T50, sdlog=sigma)
y

#> [1] 0.01409169

## Evaluate a use CDF or failure rate for a T-hour stress test 
## for a lognormal distribution.
## T = length of test
## p = proportion of failures
## sigma = shape parameter
## A = acceleration factor

T50STRESS = T*qlnorm(p, sdlog=sigma) 

CDF = plnorm((100000/(A*T50STRESS)), sdlog=sigma)

## Evaluate a use CDF or failure rate for a T-hour stress test
## for a Weibull distribution. 
## gamma = shape parameter

ASTRESS = T*qweibull(p, shape=gamma)

CDF = pweibull((100000/(A*ASTRESS)), gamma)


#R commands and output:

## Example posterior gamma inverse CDF probabilities.
p09 = 1/qgamma(0.9, shape=4, scale=1/3309)
p09

###> [1] 495.3012

p08 = 1/qgamma(0.8, shape=4, scale=1/3309)
p08

###> [1] 599.995

p05 = 1/qgamma(0.5, shape=4, scale=1/3309)
p05

###> [1] 901.1289

p01 = 1/qgamma(0.1, shape=4, scale=1/3309)
p01

###> [1] 1896.526


## Generate data for plotting.
prob = seq(0.1,1,0.001)
obj = 1/qgamma(prob, shape=4, scale=1/3309)

## Plot posterior probabilities.
plot(obj,prob, type="l", xlab="MTBF Objective",
     ylab="Probability of Exceeding Objective",
     main="Posterior (after test) Gamma Distribution Plot")
abline(v=p09, col="blue")
abline(v=p08, col="blue")
abline(v=p05, col="blue")
abline(v=p01, col="blue")


## Compute the percentile for the reciprocal mean.
pgamma(4/3309, shape=4, scale=1/3309)

###> [1] 0.5665299
#R commands and output:

## Read data and compute summary statistics.
y <- scan("../res/zarr13.dat",skip=25)
ybar = mean(y)
std = sd(y)
n = length(y)
stderr = std/sqrt(n)
Statistics = c(round(length(y),0),round(ybar,5),round(std,5),
               round(stderr,5))
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                     "Std. Dev. of Mean")

## Compute confidence intervals.
alpha = c(.5, .25, .10, .05, .01, .001, .0001, .00001)
Conf.Level = 100*(1-alpha)
Tvalue = qt(1-alpha/2,df=n-1)
Halfwidth = Tvalue*stderr
Lower = ybar - Tvalue*stderr
Upper = ybar + Tvalue*stderr
ci = round(cbind(alpha, Conf.Level, Tvalue, Halfwidth, Lower, Upper),6)

## Print results.
data.frame(Statistics)
#>                         Statistics
#> Number of Observations   195.00000
#> Mean                       9.26146
#> Std. Dev.                  0.02279
#> Std. Dev. of Mean          0.00163

data.frame(ci)

#>     alpha Conf.Level   Tvalue Halfwidth    Lower    Upper
#> 1 0.50000     50.000 0.675756  0.001103 9.260358 9.262564
#> 2 0.25000     75.000 1.153804  0.001883 9.259578 9.263344
#> 3 0.10000     90.000 1.652746  0.002697 9.258764 9.264158
#> 4 0.05000     95.000 1.972268  0.003219 9.258242 9.264679
#> 5 0.01000     99.000 2.601409  0.004245 9.257215 9.265706
#> 6 0.00100     99.900 3.341382  0.005453 9.256008 9.266914
#> 7 0.00010     99.990 3.973014  0.006484 9.254977 9.267944
#> 8 0.00001     99.999 4.536689  0.007404 9.254057 9.268864


## Perform one sample t-test.
z = t.test(y,alternative="two.sided",mu=5)

#>         One Sample t-test
#> data:  y 
#> t = 2611.286, df = 194, p-value < 2.2e-16
#> alternative hypothesis: true mean is not equal to 5 
#> 95 percent confidence interval:
#>  9.258242 9.264679 
#> sample estimates:
#> mean of x 
#>   9.26146 


#R commands and output:

## Read data and save variables.
y <- matrix(scan("../res/auto83b.dat",skip=25),ncol=2,byrow=T)
usmpg = y[,1]
jmpg  = y[,2]
jmpg  = jmpg[jmpg!=-999]

## Perform two-sample t-test.
z = t.test(usmpg,jmpg,var.equal=TRUE)

#> Case 1:  Equal Variances
#>
#>         Two Sample t-test
#>
#> data:  usmpg and jmpg 
#> t = -12.6206, df = 326, p-value < 2.2e-16
#> alternative hypothesis: true difference in means is not equal to 0 
#> 95 percent confidence interval:
#>  -11.947653  -8.725216 
#> sample estimates:
#> mean of x mean of y 
#>  20.14458  30.48101 

## Find one-tailed and two-tailed critical values.
qt(.05,z$parameter)

#> -1.649541

qt(.025,z$parameter)

#> [1] -1.967268




#R commands and output:

## Read data and save variables.
m <- matrix(scan("../res/gear.dat",skip=25),ncol=2,byrow=T)
diameter = m[,1]
batch = as.factor(m[,2])

## Fit one-way anova model.
aov.out = aov(diameter ~ batch)
summary(aov.out)

#>             Df   Sum Sq   Mean Sq F value Pr(#>F)  
#> batch        9 0.000729 8.100e-05   2.297 0.0227 *
#> Residuals   90 0.003174 3.527e-05                 
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1

## Output the residual standard deviation.
sqrt(sum(resid(aov.out)^2)/aov.out$df.resid)

#> [1] 0.005938574

## Print the critical F value.
qf(0.95,9,90)

#> [1] 1.985595

## Print the batch effects.
q = summary(lm(diameter~ batch-1))
q$coefficients[,1:2]

#>         Estimate  Std. Error
#> batch1    0.9980 0.001877942
#> batch2    0.9991 0.001877942
#> batch3    0.9954 0.001877942
#> batch4    0.9982 0.001877942
#> batch5    0.9919 0.001877942
#> batch6    0.9988 0.001877942
#> batch7    1.0015 0.001877942
#> batch8    1.0004 0.001877942
#> batch9    0.9983 0.001877942
#> batch10   0.9948 0.001877942

#R commands and output:

## Read data and save variables as factors.
m <- matrix(scan("../res/jahanmi2.dat",skip=50),ncol=16,byrow=T)
strength = m[,5]
speed = as.factor(m[,6])
feedrate = as.factor(m[,7])
grit = as.factor(m[,8])
batch = as.factor(m[,14])

## Fit the model and print the anova table.
fit.lm = lm(strength ~ speed + feedrate + grit + batch)
summary.aov(fit.lm)

#>              Df  Sum Sq Mean Sq  F value    Pr(#>F)    
#> speed         1   26673   26673   6.7081  0.009892 ** 
#> feedrate      1   11524   11524   2.8983  0.089327 .  
#> grit          1   14380   14380   3.6164  0.057818 .  
#> batch         1  727138  727138 182.8690 < 2.2e-16 ***
#> Residuals   475 1888731    3976                       
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1  

## Print effect estimates.
summary(fit.lm)

#> Call:
#> lm(formula = strength ~ speed + feedrate + grit + batch)

#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -309.784  -31.082    3.651   34.923  203.617 

#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  697.027      6.436 108.305   <2e-16 ***
#> speed1       -14.909      5.756  -2.590   0.0099 ** 
#> feedrate1      9.800      5.756   1.702   0.0893 .  
#> grit1        -10.947      5.756  -1.902   0.0578 .  
#> batch2       -77.843      5.756 -13.523   <2e-16 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 

#> Residual standard error: 63.06 on 475 degrees of freedom
#> Multiple R-squared: 0.2922,     Adjusted R-squared: 0.2862 
#> F-statistic: 49.02 on 4 and 475 DF,  p-value: < 2.2e-16#R commands and output:

## Read data and save batch variable as a factor.
m <- matrix(scan("../res/gear.dat",skip=25),ncol=2,byrow=T)
diameter = m[,1]
batch = as.factor(m[,2])

## Run Bartlett's test.
bartlett.test(diameter~batch)

#>         Bartlett test of homogeneity of variances

#> data:  diameter by batch 
#> Bartlett's K-squared = 20.7859, df = 9, p-value = 0.01364

## Find critical value.
#> qchisq(.95,9)

#> [1] 16.91898
#R commands and output:

## Read data.
m <- matrix(scan("../res/gear.dat",skip=25),ncol=2,byrow=T)
diameter = m[,1]

## Create function to perform chi-square test.
var.interval = function(data,sigma0,conf.level = 0.95) {
  df = length(data) - 1
  chilower = qchisq((1 - conf.level)/2, df)
  chiupper = qchisq((1 - conf.level)/2, df, lower.tail = FALSE)
  v = var(data)
  testchi = df*v/(sigma0^2)
  alpha = 1-conf.level

  print(paste("Standard deviation = ", round(sqrt(v),4)),quote=FALSE)
  print(paste("Test statistic = ", round(testchi,4)),quote=FALSE)
  print(paste("Degrees of freedom = ", round(df,0)),quote=FALSE)
  print(" ",quote=FALSE)
  print("Two-tailed test critical values, alpha=0.05",quote=FALSE)
  print(paste("Lower = ", round(qchisq(alpha/2,df),4)),quote=FALSE)
  print(paste("Upper = ", round(qchisq(1-alpha/2,df),4)),quote=FALSE)
  print(" ",quote=FALSE)
  print("95% Confidence Interval for Standard Deviation",quote=FALSE)
  print(c(round(sqrt(df * v/chiupper),4), 
         round(sqrt(df * v/chilower),4)),quote=FALSE)
}

## Perform chi-square test.
 var.interval(diameter,0.1)

#> [1] Standard deviation =  0.0063
#> [1] Test statistic =  0.3903
#> [1] Degrees of freedom =  99
#> [1]  
#> [1] Two-tailed test critical values, alpha=0.05
#> [1] Lower =  73.3611
#> [1] Upper =  128.422
#> [1]  
#> [1] 95% Confidence Interval for Standard Deviation
#> [1] 0.0055 0.0073#R commands and output:

## Read data and save batch as a factor.
m <- matrix(scan("JAHANMI2.DAT",skip=50),ncol=16,byrow=T)
strength = m[,5]
batch = as.factor(m[,14])

## Perform F test.
var.test(strength~batch)

#>         F test to compare two variances

#> data:  strength by batch 
#> F = 1.123, num df = 239, denom df = 239, p-value = 0.3704
#> alternative hypothesis: true ratio of variances is not equal to 1 
#> 95 percent confidence interval:
#>  0.8709874 1.4480271 
#> sample estimates:
#> ratio of variances 
#>           1.123038

## Find critical values for the F test.
qf(.025,239,239)

#> [1] 0.7755639

qf(.975,239,239)

#> [1] 1.289384#R commands and output:

## Read data and save batch as a factor.
m <- matrix(scan("../res/gear.dat",skip=25),ncol=2,byrow=T)
diameter = m[,1]
batch = as.factor(m[,2])
batch

## Attach "car" library and run Levene's test.
library(car)
leveneTest(diameter, batch)

#> Levene's Test for Homogeneity of Variance
#>       Df F value  Pr(>F)  
#> group  9  1.7059 0.09908 .
#>       90                    
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 

## Compute critical value.
qf(.95,9,90)

#> [1] 1.985595#R code and output:

## Read data.
diameter <- scan("../res/lew.dat",skip=25)

## Attach "nlme" library and compute autocorrelations.
library(nlme)
z = acf(diameter,lag.max=49)

## Print results.
Lag = round(z$lag,2)
ACF = round(z$acf,2)
data.frame(Lag, ACF)

#>    Lag   ACF
#> 1    0  1.00
#> 2    1 -0.31
#> 3    2 -0.74
#> 4    3  0.77
#> 5    4  0.21
#> 6    5 -0.90
#> 7    6  0.38
#> 8    7  0.63
#> 9    8 -0.77
#> 10   9 -0.12
#> 11  10  0.82
#> 12  11 -0.40
#> 13  12 -0.55
#> 14  13  0.73
#> 15  14  0.07
#> 16  15 -0.76
#> 17  16  0.40
#> 18  17  0.48
#> 19  18 -0.70
#> 20  19 -0.03
#> 21  20  0.70
#> 22  21 -0.41
#> 23  22 -0.43
#> 24  23  0.67
#> 25  24  0.00
#> 26  25 -0.66
#> 27  26  0.42
#> 28  27  0.39
#> 29  28 -0.65
#> 30  29  0.03
#> 31  30  0.63
#> 32  31 -0.42
#> 33  32 -0.36
#> 34  33  0.64
#> 35  34 -0.05
#> 36  35 -0.60
#> 37  36  0.43
#> 38  37  0.32
#> 39  38 -0.64
#> 40  39  0.08
#> 41  40  0.58
#> 42  41 -0.45
#> 43  42 -0.28
#> 44  43  0.62
#> 45  44 -0.10
#> 46  45 -0.55
#> 47  46  0.45
#> 48  47  0.25
#> 49  48 -0.61
#> 50  49  0.14
#R commands and output:

## Read data.
diameter <- scan("../res/lew.dat",skip=25)

## Attach "lawstat" library and peform runs test.
library(lawstat)
runs.test(diameter,alternative="two.sided")

#>         Runs Test - Two sided

#> data:  diameter 
#> Standardized Runs Statistic = 2.6938, p-value = 0.007065

## Compute critical value.
qnorm(.975)

#> [1] 1.959964

#R commands and output:

## Attach "nortest" library and define sample size.
#install.packages("nortest")
library(nortest)
n=1000


## Generate 1000 standard normal random numbers 
## and perform the Anderson-Darling test.
set.seed(403)
y1 = rnorm(n, mean = 0, sd = 1)
ad.test(y1)

#>         Anderson-Darling normality test
#>
#> data:  y1 
#> A = 0.3093, p-value = 0.5568


## Generate 1000 double exponential random numbers 
## and perform the Anderson-Darling test.
set.seed(403)
y2 = rexp(n,rate=1) - rexp(n,rate=1)
ad.test(y2)

#>         Anderson-Darling normality test
#>
#> data:  y2 
#> A = 13.6652, p-value < 2.2e-16


## Generate 1000 Cauchy random numbers and perform the 
## Anderson-Darling test.
##
## We set the seed=0 to ensure reproducibility of results.  
## Cauchy random number generators can produce very extreme 
## values.  A different seed will produce different results.
##
## Extreme values, such as might be encountered with 
## Cauchy-type data, can result in "Inf" values for the 
## Anderson-Darling test, and this is indicative of the 
## numerical limits of the Anderson-Darling implementation.  
## The p-value is not meaningful in this case.
set.seed(0)
y3 = rcauchy(n, location = 0, scale = 1)
ad.test(y3)

#>         Anderson-Darling normality test
#>
#> data:  y3
#> A = 273.668, p-value < 2.2e-16


## Generate 1000 log-normal random numbers and
## perform the Anderson-Darling test.
set.seed(403)
y4 = rlnorm(n, meanlog = 0, sdlog = 1)
ad.test(y4)

#>         Anderson-Darling normality test
#>
#> data:  y4
#> A = 91.4793, p-value < 2.2e-16


#R commands and output:

## Attach the "nortest" library that contains the chi-square test.
library(nortest)
n=1000


## Generate normal random numbers and perform the chi-square test.
y1 = rnorm(n, mean = 0, sd = 1)
pearson.test(y1)

#>         Pearson chi-square normality test
#>
#> data:  y1 
#> P = 32.256, p-value = 0.3087


## Generate double exponential random numbers and perform
## the chi-square test.
y2 = ifelse(runif(n) > 0.5, 1, -1) * rexp(n) 
pearson.test(y2)

#>         Pearson chi-square normality test
#>
#> data:  y2 
#> P = 91.776, p-value = 1.935e-08


## Generate t random numbers and perform the chi-square test.
y3 = rt(n, 3)
pearson.test(y3)

#>         Pearson chi-square normality test
#>
#> data:  y3 
#> P = 101.488, p-value = 5.647e-10


## Generate lognormal random numbers and perform the chi-square test.
y4 = rlnorm(n, meanlog = 0, sdlog = 1)
z = pearson.test(y4)
z

#>         Pearson chi-square normality test
#>
#> data:  y4 
#> P = 1085.104, p-value < 2.2e-16


## Compute critical value.
qchisq(.05,z$n.classes-3,lower.tail=FALSE)

###> [1] 42.55697

#R commands and output:

## Set sample size.
n=1000

## Generate normal random numbers and perform
## Kolmogorov-Smirnov test.
y1 = rnorm(n, mean = 0, sd = 1)
ks.test(y1,"pnorm")

#>         One-sample Kolmogorov-Smirnov test
#>
#> data:  y1 
#> D = 0.0344, p-value = 0.1874
#> alternative hypothesis: two-sided 


## Generate double exponential random numbers and 
## perform Kolmogorov-Smirnov test.
y2 = ifelse(runif(n) > 0.5, 1, -1) * rexp(n) 
ks.test(y2,"pnorm")

#>         One-sample Kolmogorov-Smirnov test
#>
#> data:  y2 
#> D = 0.0533, p-value = 0.006883
#> alternative hypothesis: two-sided 


## Generate t (3 degrees of freedom) random 
## numbers and perform Kolmogorov-Smirnov test.
y3 = rt(n, 3)
ks.test(y3,"pnorm")

#>         One-sample Kolmogorov-Smirnov test
#>
#> data:  y3 
#> D = 0.0571, p-value = 0.002961
#> alternative hypothesis: two-sided 


## Generate lognormal random numbers and perform
## Kolmogorov-Smirnov test.
y4 = rlnorm(n, meanlog = 0, sdlog = 1)
ks.test(y4,"pnorm")

#>         One-sample Kolmogorov-Smirnov test
#>
#> data:  y4 
#> D = 0.5442, p-value < 2.2e-16
#> alternative hypothesis: two-sided 

#R commands and output:

## Input data from the Tietjen and Moore paper.
y = c(199.31,199.53,200.19,200.82,201.92,201.95,202.18,245.57)

## Generate normal probability plot.
qqnorm(y,main="Normal Probability Plot of Mass Spectrometer Measurements")

## Attach "outliers" library and perform Grubbs test for one outlier.
#install.packages("outliers")
library(outliers)
grubbs.test(y,type=10)

#>         Grubbs test for one outlier
#>
#> data:  y 
#> G = 2.4688, U = 0.0049, p-value = 1.501e-07
#> alternative hypothesis: highest value 245.57 is an outlier#R commands and output:

## Input data.
x = c(-1.40, -0.44, -0.30, -0.24, -0.22, -0.13, -0.05,
       0.06, 0.10, 0.18, 0.20, 0.39, 0.48, 0.63, 1.01)

## Specify k, the number of outliers being tested.
k = 2

## Generate normal probability plot.
qqnorm(x)

## Create a function to compute statistic to
## test for outliers in both tails.
tm = function(x,k){

n = length(x)

## Compute the absolute residuals.
r = abs(x - mean(x))

## Sort data according to size of residual.
df = data.frame(x,r)
dfs = df[order(df$r),]

## Create a subset of the data without the largest k values.
klarge = c((n-k+1):n)
subx = dfs$x[-klarge]

## Compute the sums of squares.
ksub = (subx - mean(subx))**2
all = (df$x - mean(df$x))**2

## Compute the test statistic.
ek = sum(ksub)/sum(all)
}

## Call the function and compute value of test statistic for data.
ekstat = tm(x,k)
ekstat

#> [1] 0.2919994

## Compute critical value based on simulation.
test = c(1:10000)
for (i in 1:10000){
xx = rnorm(length(x))
test[i] = tm(xx,k)}
quantile(test,0.05)

#>        5% 
#> 0.3150342
#R commands and output:

## Input data.
y = c(-0.25, 0.68, 0.94, 1.15, 1.20, 1.26, 1.26,
       1.34, 1.38, 1.43, 1.49, 1.49, 1.55, 1.56,
       1.58, 1.65, 1.69, 1.70, 1.76, 1.77, 1.81,
       1.91, 1.94, 1.96, 1.99, 2.06, 2.09, 2.10,
       2.14, 2.15, 2.23, 2.24, 2.26, 2.35, 2.37,
       2.40, 2.47, 2.54, 2.62, 2.64, 2.90, 2.92,
       2.92, 2.93, 3.21, 3.26, 3.30, 3.59, 3.68,
       4.30, 4.64, 5.34, 5.42, 6.01)

## Generate normal probability plot.
qqnorm(y)

## Create function to compute the test statistic.
rval = function(y){
       ares = abs(y - mean(y))/sd(y)
       df = data.frame(y, ares)
       r = max(df$ares)
       list(r, df)}

## Define values and vectors.
n = length(y)
alpha = 0.05
lam = c(1:10)
R = c(1:10)

## Compute test statistic until r=10 values have been
## removed from the sample.
for (i in 1:10){

if(i==1){
rt = rval(y)
R[i] = unlist(rt[1])
df = data.frame(rt[2])
newdf = df[df$ares!=max(df$ares),]}

else if(i!=1){
rt = rval(newdf$y)
R[i] = unlist(rt[1])
df = data.frame(rt[2])
newdf = df[df$ares!=max(df$ares),]}

## Compute critical value.
p = 1 - alpha/(2*(n-i+1))
t = qt(p,(n-i-1))
lam[i] = t*(n-i) / sqrt((n-i-1+t**2)*(n-i+1))

}
## Print results.
newdf = data.frame(c(1:10),R,lam)
names(newdf)=c("No. Outliers","Test Stat.", "Critical Val.")
newdf

###>    No. Outliers Test Stat. Critical Val.
###> 1             1   3.118906      3.158794
###> 2             2   2.942973      3.151430
###> 3             3   3.179424      3.143890
###> 4             4   2.810181      3.136165
###> 5             5   2.815580      3.128247
###> 6             6   2.848172      3.120128
###> 7             7   2.279327      3.111796
###> 8             8   2.310366      3.103243
###> 9             9   2.101581      3.094456
###> 10           10   2.067178      3.085425



######################################################################
## ================================================================ ##
#######################################################################R commands and output:

## Input data and create variables.
m <- matrix(scan("../res/splett3.dat",skip=25),ncol=5,byrow=T)
y  = m[,1]
x1 = m[,2]
x2 = m[,3]
x3 = m[,4]

## Compute the pseudo-replication standard deviation 
## (assuming all 3rd order and higher interactions are 
## really due to random error).
z = lm(y ~ 1 + x1 + x2 + x3 + x1*x2 + x1*x3 + x2*x3)
summary(z)$sigma

#> [1] 0.2015254

## Compute the standard deviation of a coefficient based 
## on the pseudo-replication standard deviation.
summary(z)$coefficients[2,2]

#> [1] 0.07125

## Save t-values based on pseudo-replication standard deviation.
t1 = summary(z)$coefficients[2,3]
t2 = summary(z)$coefficients[3,3]
t23 = summary(z)$coefficients[7,3]
t13 = summary(z)$coefficients[6,3]
t3 = summary(z)$coefficients[4,3]
t123 = 1
t12 = summary(z)$coefficients[5,3]
Tvalue = round(rbind(NaN,t1,t2,t23,t13,t3,t123,t12),2)

## Compute the effect estimate and residual standard deviation
## for each model (mean plus the effect).

z = lm(y ~ 1)
mean = summary(z)$coefficients[1]
ese = summary(z)$sigma

z = lm(y ~ 1 + x1)
e1 = 2*summary(z)$coefficients[2]
e1se = summary(z)$sigma

z = lm(y ~ 1 + x2)
e2 = 2*summary(z)$coefficients[2]
e2se = summary(z)$sigma

z = lm(y ~ 1 + x2:x3)
e23 = 2*summary(z)$coefficients[2]
e23se = summary(z)$sigma

z = lm(y ~ 1 + x1:x3)
e13 = 2*summary(z)$coefficients[2]
e13se = summary(z)$sigma

z = lm(y ~ 1 + x3)
e3 = 2*summary(z)$coefficients[2]
e3se = summary(z)$sigma

z = lm(y ~ 1 + x1:x2:x3)
e123 = 2*summary(z)$coefficients[2]
e123se = summary(z)$sigma

z = lm(y ~ 1 + x1:x2)
e12 = 2*summary(z)$coefficients[2]
e12se = summary(z)$sigma

Effect = rbind(mean,e1,e2,e23,e13,e3,e123,e12)
Eff.SE = rbind(ese,e1se,e2se,e23se,e13se,e3se,e123se,e12se)

## Compute the residual standard deviation for cumulative
## models (mean plus cumulative terms).

z = lm(y ~ 1)
ce = summary(z)$sigma
z = lm(y ~ 1 + x1)
ce1 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2)
ce2 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2 + x2:x3)
ce3 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2 + x2:x3 + x1:x3)
ce4 = summary(z)$sigma
z = lm(y ~ 1 + x1 + x2 + x2:x3 + x1:x3 + x3)
ce5 = summary(z)$sigma
z = lm(y ~ x1 + x2 + x2:x3 + x1:x3 + x3 + x1:x2:x3)
ce6 = summary(z)$sigma
z = lm(y ~ 1 + x1*x2*x3)
ce7 = summary(z)$sigma

Cum.Eff = rbind(ce,ce1,ce2,ce3,ce4,ce5,ce6,ce7)

## Combine the results into a dataframe.
round(data.frame(Effect, Tvalue, Eff.SE, Cum.Eff),5)

#>        Effect Tvalue  Eff.SE Cum.Eff
#> mean  2.65875    NaN 1.74106 1.74106
#> e1    3.10250  21.77 0.57272 0.57272
#> e2   -0.86750  -6.09 1.81264 0.30429
#> e23   0.29750   2.09 1.87270 0.26737
#> e13   0.24750   1.74 1.87513 0.23341
#> e3    0.21250   1.49 1.87656 0.19121
#> e123  0.14250   1.00 1.87876 0.18031
#> e12   0.12750   0.89 1.87912     NaN
#R commands and output:

## Read normal data.
y <- scan("../res/randn.dat",skip=25)


## Generate a 4-plot of the data. 
library(Hmisc)
t = 1:length(y)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Normal Random Numbers:  4-Plot", line = 0.5, outer = TRUE)

## Generate separate plots to show more detail.
par(mfrow=c(1,1))
plot(t,y,ylab="Y",xlab="Index",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y",freq=FALSE)
curve(dnorm(x,mean=mean(y),sd=sd(y)), add=TRUE, col="blue")
qqnorm(y,main="")
qqline(y,col=2)


## Compute summary statistics.
n = round(length(y),0)
ybar = round(mean(y),5)
std = round(sd(y),5)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)
rany = round((max(y)-min(y)),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
z
lhinge = round(z[2],5)
uhinge = round(z[4],5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations   500.00000
#> Mean                      -0.00294
#> Std. Dev.                  1.02104
#> Std. Dev. of Mean          0.04566
#> Variance                   1.04253
#> Range                      6.08300
#> Lower Hinge               -0.72100
#> Upper Hinge                0.64550
#> Inter-Quartile Range       1.36525
#> Autocorrelation            0.04506

summary(y)

#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#> -2.647000 -0.720500 -0.093000 -0.002936  0.644700  3.436000 


## Generate index variable and fit straight line.
x = c(1:length(y))
lm(y ~ 1 + x)
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -2.6372 -0.7095 -0.0908  0.6485  3.4307 
#>
#> Coefficients:
#>               Estimate Std. Error t value Pr(#>|t|)
#> (Intercept)  6.991e-03  9.155e-02   0.076     0.94
#> x           -3.963e-05  3.167e-04  -0.125     0.90
#>
#> Residual standard error: 1.022 on 498 degrees of freedom
#> Multiple R-squared: 3.145e-05,  Adjusted R-squared: -0.001977 
#> F-statistic: 0.01566 on 1 and 498 DF,  p-value: 0.9005 


## Generate arbitrary interval indicator variable and
## run Bartlett's test.
int = as.factor(rep(1:4,each=125))
bartlett.test(y~int)

#>         Bartlett test of homogeneity of variances
#>
#> data:  y by int 
#> Bartlett's K-squared = 2.3737, df = 3, p-value = 0.4986

## Determine critical value for the test.
qchisq(.95,3)

#> [1] 7.814728


## Generate and plot the autocorrelation function.
z = acf(y,lag.max=21)
plot(z,ci=c(.90,.95),main="",ylab="Autocorrelation")


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>         Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = -1.0744, p-value = 0.2826


## Load the nortest library and perform the Anderson-Darling
## normality test.
library(nortest)
ad.test(y)

#>         Anderson-Darling normality test
#>
#> data:  y 
#> A = 1.0612, p-value = 0.008626


## Load the outliers library and perform the Grubbs test.
library(outliers)
grubbs.test(y,type=10)

#>         Grubbs test for one outlier
#>
#> data:  y 
#> G = 3.3681, U = 0.9772, p-value = 0.1774
#> alternative hypothesis: highest value 3.436 is an outlier 

#R commands and output:

## Read uniform data.
y = scan("../res/randu.dat",skip=25)


## Generate a 4-plot of the data. 
library(Hmisc)
t = 1:length(y)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Uniform Random Numbers:  4-Plot", line = 0.5, outer = TRUE)

## Generate separate plots to show more detail.
par(mfrow=c(1,1))
plot(t,y,ylab="Y",xlab="Index",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")

## Plot histogram with overlayed normal distribution.
hist(y,main="",xlab="Y",freq=FALSE,ylim=c(0,1.5))
curve(dnorm(x,mean=mean(y),sd=sd(y)), add=TRUE, col="blue")

## Plot histogram with overlayed uniform distribution.
hist(y,main="",xlab="Y",freq=FALSE,ylim=c(0,1.5))
curve(dunif(x), add=TRUE, col="blue")

## Normal probability plot.
qqnorm(y,main="")
qqline(y,col=2)

## Uniform probability plot.
library(gap)
qqunif(y,main="")


## Attach boot library and generate values for bootstrap plot.
library(boot)

## Bootstrap and CI for mean.  d is a vector of integer indexes
samplemean <- function(x, d) {
  return(mean(x[d]))                   
}
b1 = boot(y, samplemean, R=500)   
z1 = boot.ci(b1, conf=0.9, type="basic")
meanci = paste("90% CI: ", "(", round(z1$basic[4],4), ", ", 
               round(z1$basic[5],4), ")", sep="" )

## Bootstrap and CI for median.
samplemedian <- function(x, d) {
  return(median(x[d]))          
}
b2 = boot(y, samplemedian, R=500)
z2 = boot.ci(b2, conf=0.90, type="basic")
medci = paste("90% CI: ", "(", round(z2$basic[4],4), ", ", 
              round(z2$basic[5],4), ")", sep="" )

## Bootstrap and CI for midrange.
samplemidran <- function(x, d) {
  return( (max(x[d])+min(x[d]))/2 )
}
b3 = boot(y, samplemidran, R=500)   
z3 = boot.ci(b3, conf=0.90, type="basic")
midci = paste("90% CI: ", "(", round(z3$basic[4],4), ", ", 
              round(z3$basic[5],4), ")", sep="" )

## Generate bootstrap plot.
par(mfrow=c(2,3))
plot(b1$t,type="l",ylab="Mean",main=meanci)
plot(b2$t,type="l",ylab="Median",main=medci)
plot(b3$t,type="l",ylab="Midrange",main=midci)
hist(b1$t,main="Bootstrap Mean",xlab="Mean")
hist(b2$t,main="Bootstrap Median",xlab="Median")
hist(b3$t,main="Bootstrap Midrange",xlab="Midrange")
par(mfrow=c(1,1))


## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations   500.00000
#> Mean                       0.50783
#> Std. Dev.                  0.29433
#> Std. Dev. of Mean          0.01316
#> Variance                   0.08663
#> Range                      0.99459
#> Lower Hinge                0.25059
#> Upper Hinge                0.75948
#> Inter-Quartile Range       0.50831
#> Autocorrelation           -0.03099

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> 0.00249 0.25080 0.51840 0.50780 0.75910 0.99710 


## Compute probabilty plot correlation coefficients (PPCC)
## for normal and uniform distributions
x = qqnorm(y)
cor(x$x,y)

#> [1] 0.9762727
#install.packages("gap")
library(gap)
u = qqunif(y,logscale=FALSE)
cor(u$x,sort(y))

#> [1] 0.9995683


## Generate index variable and fit straight line.
x = c(1:length(y))
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>       Min        1Q    Median        3Q       Max 
#> -0.504587 -0.259594  0.003748  0.254196  0.494785 
#>
#> Coefficients:
#>               Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  5.229e-01  2.638e-02   19.82   <2e-16 ***
#> x           -6.025e-05  9.125e-05   -0.66    0.509    
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 0.2945 on 498 degrees of freedom
#> Multiple R-squared: 0.0008747,  Adjusted R-squared: -0.001132 
#> F-statistic: 0.436 on 1 and 498 DF,  p-value: 0.5094 

## Critical value to test that the slope is different from zero.
qt(.975,498)

#> [1] 1.964739


## Load the car library, generate an arbitrary interval indicator 
## variable and run Levene's test.
int = as.factor(rep(1:4,each=125))
library(car)
leveneTest(y,int)

#> Levene's Test for Homogeneity of Variance
#>        Df F value Pr(#>F)
#> group   3  0.0798  0.971
#>       496 

## Upper critical value for the F test.
qf(.95,3,496)

#> [1]  2.622879


## Generate and plot the autocorrelation function.
z = acf(y,lag.max=21)
plot(z,ci=c(.90,.95),main="",ylab="Autocorrelation")


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>         Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = 0.2686, p-value = 0.7882

## Determine critical value for the test.

qnorm(.975)

#> [1] 1.959964


## Load the nortest library and perform the Anderson-Darling
## normality test.
library(nortest)
ad.test(y)

#>         Anderson-Darling normality test
#>
#> data:  y 
#> A = 5.7198, p-value = 4.206e-14
#R commands and output:

## Read random walk data.
y <- scan("../res/randwalk.dat",skip=25)


## Generate 4-plot.
library(Hmisc)
t = 1:length(y)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Random Walk:  4-Plot", line = 0.5, outer = TRUE)
par(mfrow=c(2,2))

## Generate spectral plot.
z = spec.pgram(y,kernel,spans=3,plot=FALSE)
plot(z$freq,z$spec,type="l",ylab="Spectrum",xlab="Frequency")


## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations   500.00000
#> Mean                       3.21668
#> Std. Dev.                  2.07867
#> Std. Dev. of Mean          0.09296
#> Variance                   4.32089
#> Range                      9.05359
#> Lower Hinge                1.74104
#> Upper Hinge                4.68227
#> Inter-Quartile Range       2.93447
#> Autocorrelation            0.98686

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>  -1.638   1.747   3.612   3.217   4.682   7.415 


## Generate index variable and fit straight line.
x = c(1:length(y))
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -3.76455 -1.56702 -0.09758  1.59580  4.33380 
#>
#> Coefficients:
#>              Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept) 1.8335107  0.1721148  10.653   <2e-16 ***
#> x           0.0055216  0.0005953   9.275   <2e-16 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 1.921 on 498 degrees of freedom
#> Multiple R-squared: 0.1473,     Adjusted R-squared: 0.1456 
#> F-statistic: 86.02 on 1 and 498 DF,  p-value: < 2.2e-16 


## Load the car library, generate an arbitrary interval indicator 
## variable and run Levene's test.
int = as.factor(rep(1:4,each=125))
library(car)
leveneTest(y,int)

#> Levene's Test for Homogeneity of Variance
#>        Df F value    Pr(#>F)    
#> group   3  10.459 1.106e-06 ***
#>       496                      
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 

## Critical value.
qf(.95,3,496)

#> [1] 2.622879


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>         Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = -20.3239, p-value < 2.2e-16

## Determine critical value for the test.
qnorm(.975)

#> [1] 1.959964


## Attach Hmisc library and perform the linear fit.
library(Hmisc)
z = lm(y ~ Lag(y))
summary(z)

#> Call:
#> lm(formula = y ~ Lag(y))
#>
#> Residuals:
#>       Min        1Q    Median        3Q       Max 
#> -0.519254 -0.245457  0.001945  0.244185  0.507424 
#>
#> Coefficients:
#>             Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept) 0.050165   0.024171   2.075   0.0385 *  
#> Lag(y)      0.987087   0.006313 156.350   <2e-16 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 

#> Residual standard error: 0.2931 on 497 degrees of freedom
#>   (1 observation deleted due to missingness)
#> Multiple R-squared: 0.9801,     Adjusted R-squared:  0.98 
#> F-statistic: 2.445e+04 on 1 and 497 DF,  p-value: < 2.2e-16 


## Generate plot of predicted versus observed.
p = predict(z)
plot(p,y[-1],xlab="Y",ylab="Predicted")


## Generate 4-plot of residuals.
t = 1:length(z$residual)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,z$residuals,ylab="Residuals",xlab="Run Sequence",type="l")
plot(z$residual,Lag(z$residual),xlab="Residual[i-1]",ylab="Residual[i]")
hist(z$residual,main="",xlab="Residual")
qqnorm(z$residual,main="")
mtext("Random Walk:  4-Plot", line = 0.5, outer = TRUE)
par(mfrow=c(1,1))


## Generate uniform probability plot.
library(gap)
qqunif(z$residuals,main="",logscale=FALSE,lcol=0)#R commands and output:

## Read data.
y <- scan("../res/soulen.dat",skip=25)


## Generate a 4-plot of the data. 
library(Hmisc)
t = 1:length(y)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Voltage Counts:  4-Plot", line = 0.5, outer = TRUE)

## Generate separate plots to show more detail.
par(mfrow=c(1,1))
plot(t,y,ylab="Y",xlab="Index",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")

## Plot histogram with overlayed normal distribution.
hist(y,main="",xlab="Y",freq=FALSE)
curve(dnorm(x,mean=mean(y),sd=sd(y)), add=TRUE, col="blue")

## Normal probability plot.
qqnorm(y,main="")
qqline(y,col=2)


## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations   700.00000
#> Mean                    2898.56143
#> Std. Dev.                  1.30497
#> Std. Dev. of Mean          0.04932
#> Variance                   1.70295
#> Range                      7.00000
#> Lower Hinge             2898.00000
#> Upper Hinge             2899.00000
#> Inter-Quartile Range       1.00000
#> Autocorrelation            0.31480

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>    2895    2898    2899    2899    2899    2902 


## Generate index variable and fit straight line.
x = c(1:length(y))
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -3.5716 -0.7576  0.0804  0.7756  3.7743 
#>
#> Coefficients:
#>              Estimate Std. Error   t value Pr(#>|t|)    
#> (Intercept) 2.898e+03  9.745e-02 29739.288  < 2e-16 ***
#> x           1.071e-03  2.409e-04     4.445 1.02e-05 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 1.288 on 698 degrees of freedom
#> Multiple R-squared: 0.02753,    Adjusted R-squared: 0.02614 
#> F-statistic: 19.76 on 1 and 698 DF,  p-value: 1.021e-05 


## Load the car library, generate an arbitrary interval indicator 
## variable and run Levene's test.
int = as.factor(rep(1:4,each=175))
library(car)
leveneTest(y,int)

#> Levene's Test for Homogeneity of Variance
#>        Df F value Pr(#>F)
#> group   3  1.4324 0.2321
#>       696 

## Critical value.
qf(.95,3,696)

#> [1] 2.6177


## Generate and plot the autocorrelation function.
corr <- acf(y, lag.max=175,ci=c(.95,.99),main="")
sig_level <- qnorm((1 + 0.95)/2)/sqrt(corr$n.used)
sig_level


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>         Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = -13.4162, p-value < 2.2e-16


## Load the outliers library and perform the Grubbs test.
library(outliers)
grubbs.test(y,type=10)

#>         Grubbs test for one outlier
#> 
#> data:  y 
#> G = 2.7291, U = 0.9893, p-value = 1
#> alternative hypothesis: lowest value 2895 is an outlier 

##R commands and output:

## Read data.
y <- scan("../res/mavro.dat",skip=25)
t = 1:length(y)


## Generate a 4-plot of the data.
library(Hmisc)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Filter Transmittance Data: 4-Plot", line = 0.5, outer = TRUE)

## Generate run sequence plot.
par(mfrow=c(1,1))
plot(t,y,ylab="Y",xlab="Index",type="l")

## Generate lag plot.
par(mfrow=c(1,1))
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")


## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations    50.00000
#> Mean                       2.00186
#> Std. Dev.                  0.00043
#> Std. Dev. of Mean          0.00006
#> Variance                   0.00000
#> Range                      0.00140
#> Lower Hinge                2.00150
#> Upper Hinge                2.00210
#> Inter-Quartile Range       0.00060
#> Autocorrelation            0.93799

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   2.001   2.002   2.002   2.002   2.002   2.003 


## Generate index variable and fit straight line.
x = c(1:length(y))
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>        Min         1Q     Median         3Q        Max 
#> -5.837e-04 -3.294e-04  5.234e-05  2.952e-04  5.208e-04 
#>
#> Coefficients:
#>              Estimate Std. Error   t value Pr(#>|t|)    
#> (Intercept) 2.001e+00  9.695e-05 20644.046  < 2e-16 ***
#> x           1.847e-05  3.309e-06     5.582 1.09e-06 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 0.0003376 on 48 degrees of freedom
#> Multiple R-squared: 0.3936,     Adjusted R-squared: 0.381 
#> F-statistic: 31.15 on 1 and 48 DF,  p-value: 1.085e-06 


## Load the car library, generate an arbitrary interval indicator 
## variable and run Levene's test.
library(car)
int = as.factor(c(rep(1,each=13),rep(2:3,each=12),rep(4,each=13)))
leveneTest(y,int)

#> Levene's Test for Homogeneity of Variance
#>       Df F value Pr(#>F)
#> group  3  0.9445 0.4269
#>       46  

## Generate critical value.
qf(.975,3,46)

###> [1] 2.806845


## Generate and plot the autocorrelation function.
corr <- acf(y, lag.max=12,ci=c(.95,.99),main="")
corr$acf[2]

#> 0.9379892

sig_level <- qnorm((1 + 0.95)/2)/sqrt(corr$n.used)
sig_level

#> 0.2771808


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>     Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = -5.3246, p-value = 1.012e-07#R commands and output:

## Read data.
m = matrix(scan("../res/dziuba1.dat",skip=25),ncol=4,byrow=T)
y = m[,4]


## Generate a 4-plot of the data.  
library(Hmisc)
t = 1:length(y)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Standard Resitor Data: 4-Plot", line = 0.5, outer = TRUE)

## Generate run order plot.
par(mfrow=c(1,1))
plot(t,y,ylab="Y",xlab="Index",type="l")

## Generate lag plot.
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")


## Compute summary statistics.
ybar = round(mean(y),5)
std = round(sd(y),5)
n = round(length(y),0)
stderr = round(std/sqrt(n),5)
v = round(var(y),5)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],5)
uhinge = round(z[4],5)
rany = round((max(y)-min(y)),5)

## Compute the inter-quartile range.
iqry = round(IQR(y),5)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],5)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations  1000.00000
#> Mean                      28.01634
#> Std. Dev.                  0.06349
#> Std. Dev. of Mean          0.00201
#> Variance                   0.00403
#> Range                      0.29050
#> Lower Hinge               27.97900
#> Upper Hinge               28.06295
#> Inter-Quartile Range       0.08388
#> Autocorrelation            0.97216

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   27.83   27.98   28.03   28.02   28.06   28.12 


## Generate index variable and fit straight line.
x = c(1:length(y))
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>       Min        1Q    Median        3Q       Max 
#> -0.093259 -0.012859  0.003605  0.013953  0.051697 
#>
#> Coefficients:
#>              Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept) 2.791e+01  1.209e-03 23090.8   <2e-16 ***
#> x           2.097e-04  2.092e-06   100.2   <2e-16 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 0.0191 on 998 degrees of freedom
#> Multiple R-squared: 0.9096,     Adjusted R-squared: 0.9095 
#> F-statistic: 1.004e+04 on 1 and 998 DF,  p-value: < 2.2e-16 


## Load the car library, generate an arbitrary interval indicator 
## variable and run Levene's test.
library(car)
int = as.factor(rep(1:4,each=250))
leveneTest(y,int)

#> Levene's Test for Homogeneity of Variance
#>        Df F value    Pr(#>F)    
#> group   3  140.85 < 2.2e-16 ***
#>       996                      
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 

## Find critical value.
qf(.95,3,996)

#> [1] 2.613839


## Generate and plot the autocorrelation function.
corr <- acf(y, lag.max=250,ci=c(.95,.99),main="")
corr$acf[2]

#> 0.972159

sig_level <- qnorm((1 + 0.95)/2)/sqrt(corr$n.used)
sig_level

#> 0.0619795


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>         Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = -30.5629, p-value < 2.2e-16#R commands and output:

## Read data.
y = scan("../res/zarr13.dat",skip=25)


## Generate a 4-plot of the data.  
library(Hmisc)
t = 1:length(y)
par(mfrow = c(2, 2),
      oma = c(0, 0, 2, 0),
      mar = c(5.1, 4.1, 2.1, 2.1)) 
plot(t,y,ylab="Y",xlab="Run Sequence",type="l")
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")
hist(y,main="",xlab="Y")
qqnorm(y,main="")
mtext("Heat Flow Meter Data: 4-Plot", line = 0.5, outer = TRUE)

## Generate run order plot.
par(mfrow=c(1,1))
plot(t,y,ylab="Y",xlab="Index",type="l")

## Generate lag plot.
plot(y,Lag(y),xlab="Y[i-1]",ylab="Y[i]")

## Plot histogram with overlayed normal distribution.
hist(y,main="",xlab="Y",freq=FALSE)
curve(dnorm(x,mean=mean(y),sd=sd(y)), add=TRUE, col="blue")

## Normal probability plot.
qqnorm(y,main="")
qqline(y,col=2)


## Compute summary statistics.
ybar = round(mean(y),6)
std = round(sd(y),6)
n = round(length(y),0)
stderr = round(std/sqrt(n),6)
v = round(var(y),6)

# Compute the five number summary.
# min, lower hinge, Median, upper hinge, max
z = fivenum(y)
lhinge = round(z[2],6)
uhinge = round(z[4],6)
rany = round((max(y)-min(y)),6)

## Compute the inter-quartile range.
iqry = round(IQR(y),6)

## Compute the lag 1 autocorrelation.
z = acf(y)
ac = round(z$acf[2],6)

## Format results for printing.
Statistics = c(n,ybar,std,stderr,v,rany,lhinge,uhinge,iqry,ac)
names(Statistics)= c("Number of Observations ", "Mean", "Std. Dev.", 
                "Std. Dev. of Mean", "Variance", "Range",
                "Lower Hinge", "Upper Hinge", "Inter-Quartile Range",
                "Autocorrelation")
data.frame(Statistics)

#>                         Statistics
#> Number of Observations  195.000000
#> Mean                      9.261461
#> Std. Dev.                 0.022789
#> Std. Dev. of Mean         0.001632
#> Variance                  0.000519
#> Range                     0.131125
#> Lower Hinge               9.246496
#> Upper Hinge               9.275530
#> Inter-Quartile Range      0.029034
#> Autocorrelation           0.280578

summary(y)

#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   9.197   9.246   9.262   9.261   9.276   9.328 


## Generate index variable and fit straight line.
x = c(1:length(y))
summary(lm(y ~ 1 + x))

#> Call:
#> lm(formula = y ~ 1 + x)
#>
#> Residuals:
#>        Min         1Q     Median         3Q        Max 
#> -0.0605897 -0.0147354  0.0009425  0.0136395  0.0635789 
#>
#> Coefficients:
#>               Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept)  9.267e+00  3.253e-03 2848.98   <2e-16 ***
#> x           -5.641e-05  2.878e-05   -1.96   0.0514 .  
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#>
#> Residual standard error: 0.02262 on 193 degrees of freedom
#> Multiple R-squared: 0.01952,    Adjusted R-squared: 0.01444 
#> F-statistic: 3.842 on 1 and 193 DF,  p-value: 0.05143


## Generate arbitrary interval indicator variable and
## run Bartlett's test.
int = as.factor(c(rep(1,each=48),rep(2:4,each=49)))
bartlett.test(y~int)

#>         Bartlett test of homogeneity of variances
#>
#> data:  y by int 
#> Bartlett's K-squared = 3.1472, df = 3, p-value = 0.3695

## Critical value.
qchisq(.95,3)

#> [1] 7.814728


## Generate and plot the autocorrelation function.
corr <- acf(y, lag.max=48,ci=c(.95,.99),main="")
corr$acf[2]

#> 0.2805784

sig_level <- qnorm((1 + 0.95)/2)/sqrt(corr$n.used)
sig_level

#> 0.1403559


## Load the lawstat library and perform runs test.
library(lawstat)
runs.test(y)

#>         Runs Test - Two sided
#>
#> data:  y 
#> Standardized Runs Statistic = -3.2306, p-value = 0.001235


## Load the nortest library and perform the Anderson-Darling
## normality test.
library(nortest)
ad.test(y)

#>        Anderson-Darling normality test
#>
#> data:  y 
#> A = 0.1265, p-value = 0.985


## Load the outliers library and perform the Grubbs test.
library(outliers)
grubbs.test(y,type=10)

#>         Grubbs test for one outlier
#>
#> data:  y 
#> G = 2.9186, U = 0.9559, p-value = 0.3121
#> alternative hypothesis: highest value 9.327973 is an outlier 


## Compute the 95 % confidence interval for the mean.
u = qt(0.975,df=n-1)*std/sqrt(n)
c(ybar-u,ybar+u)

#> [1] 9.258242 9.264680
#R commands and output:

## Input data.
x = c( 370, 1016, 1235, 1419, 1567, 1820,
       706, 1018, 1238, 1420, 1578, 1868,
       716, 1020, 1252, 1420, 1594, 1881,
       746, 1055, 1258, 1450, 1602, 1890,
       785, 1085, 1262, 1452, 1604, 1893,
       797, 1102, 1269, 1475, 1608, 1895,
       844, 1102, 1270, 1478, 1630, 1910,
       855, 1108, 1290, 1481, 1642, 1923,
       858, 1115, 1293, 1485, 1674, 1940,
       886, 1120, 1300, 1502, 1730, 1945,
       886, 1134, 1310, 1505, 1750, 2023,
       930, 1140, 1313, 1513, 1750, 2100,
       960, 1199, 1315, 1522, 1763, 2130,
       988, 1200, 1330, 1522, 1768, 2215,
       990, 1200, 1355, 1530, 1781, 2268,
      1000, 1203, 1390, 1540, 1782, 2440,
      1010, 1222, 1416, 1560, 1792)

## Generate initial plots of the data.
par(mfrow=c(2,2),bg=rgb(1,1,0.8))
dotchart(x,xlab="Polished Window Strength (ksi)")
boxplot (x,ylab="Polished Window Strength (ksi)")
hist    (x,ylab="Counts",xlab="Polished Window Strength (ksi)",main="")
plot(density(x),xlab="Polished Window Strength (ksi)",main="")


## Generate QQ-plot of the data.
par(mfrow=c(1,1),bg=rgb(1,1,0.8))
qqnorm(x, pch=20, col="Red")


## Plot 99 samples from the data and compare QQ-plots to actual data.
x.ave = mean(x); x.sd = sd(x)
nx = length(x)
nb = 99
u = qnorm(ppoints(nx))
xb = array(dim=c(nx,nb))
for (jb in 1:nb) {
   xb[,jb] = sort(qqnorm(rnorm(nx, mean=x.ave, sd=x.sd),
   plot=FALSE)$y)}
par(mfrow=c(1,1),bg=rgb(1,1,0.8))
zz = qqnorm(x, pch=20, col="Red")
matplot(u, xb, type="p", pch=21, col="Blue", add=TRUE)
points(zz$x,zz$y, pch=20, col="Red")



## Compare QQ-plots of the data for various distributions 
## using maximum likelihood estimation.
require(stats4)
negloglik.gau = function (mu, sigma) {
    if (sigma < 0) {return(Inf)} else {
    -sum(dnorm(x, mean=mu, sd=sigma, log=TRUE))}}
x.gau = mle(negloglik.gau, method="Nelder-Mead",
           start=list(mu=mean(x), sigma=sd(x)))
x.gau@coef

#>        mu     sigma 
#> 1400.8145  389.3003

negloglik.gam = function (alpha, lambda) {
    if (any(c(alpha, lambda) < 0)) {return(Inf)} else {
    -sum(dgamma(x, shape=alpha, rate=lambda, log=TRUE))}}
x.gam = mle(negloglik.gam, method="Nelder-Mead",
           start=list(alpha=(mean(x)/sd(x))^2,
           lambda=mean(x)/var(x)))
x.gam@coef

#>        alpha       lambda 
#> 11.851717840  0.008459428 

require(bs)
negloglik.bs = function (alpha, beta) {
    if (any(c(alpha, beta) < 0)) {return(Inf)} else {
    -sum(dbs(x, alpha, beta, log=TRUE))}}
x.bs = mle(negloglik.bs, method="Nelder-Mead",
           start=list(alpha=0.25, beta=30))
x.bs@coef

#>        alpha         beta 
#>    0.3100202 1336.7948970 

negloglik.wei = function (xi, beta, eta) {
    -sum(dweibull(x-xi, shape=beta, scale=eta, log=TRUE)) }
x.wei = mle(negloglik.wei, method="L-BFGS-B",
            lower=c(-Inf, 0, 0),
            start=list(xi=100, beta=2, eta=15))
x.wei@coef

#>          xi        beta         eta 
#>  181.154738    3.428001 1356.441176


## Plot overlaid density for each distribution.
xl = mean(x)-3*sd(x); xu=mean(x)+3*sd(x)
plot(density(x, from=xl, to=xu), ylim=c(0, 0.0012),main="")
curve(dnorm(x, mean=x.gau@coef[1], sd=x.gau@coef[2]),
      from=xl, to=xu, col="LightBlue", add=TRUE, lwd=2)
curve(dgamma(x, shape=x.gam@coef[1], rate=x.gam@coef[2]),
      from=xl, to=xu, col="Brown", add=TRUE, lwd=2)
curve(dbs(x, alpha=x.bs@coef[1], beta=x.bs@coef[2]),
      from=xl, to=xu, col="Red", add=TRUE, lwd=2)
curve(dweibull(x-x.wei@coef[1], shape=x.wei@coef[2],
      scale=x.wei@coef[3]),
      from=xl, to=xu, col="Purple", add=TRUE, lwd=2)
legend(1700, 0.0012, bty="n",
       legend=c("Data", "Gaussian", "Gamma",
                "Birnbaum-Saunders", "Weibull"), 
       lty=c(1,1,1,1,1),
       col=c("Black","LightBlue", "Brown", "Red", "Purple"))



## Generate QQ-plots for each distribution and overlay.
xy.gau = list(x=sort(qnorm(ppoints(x),
              mean=x.gau@coef[1], sd=x.gau@coef[2])),
              y=sort(x))
xy.gam = list(x=sort(qgamma(ppoints(x),
              shape=x.gam@coef[1], rate=x.gam@coef[2])),
              y=sort(x))
xy.bs = list(x=sort(qbs(ppoints(x),
             alpha=x.bs@coef[1], beta=x.bs@coef[2])),
             y=sort(x))
xy.wei = list(x=sort(x.wei@coef[1] + qweibull(ppoints(x),
              shape=x.wei@coef[2], scale=x.wei@coef[3])),
              y=sort(x))
plot(xy.gau, pch=15, col="LightBlue",
     xlab="Theoretical Quantiles",
     ylab="Sample Quantiles")
points(xy.gam, pch=16, col="Brown")
points(xy.bs, pch=17, col="Red")
points(xy.wei, pch=18, col="Purple")
legend(500, 2400, bty="n",
       legend=c("Gaussian", "Gamma",
       "Birnbaum-Saunders", "Weibull"), pch=c(15,16,17,18),
       col=c("LightBlue", "Brown", "Red", "Purple"))



## Compute AIC and BIC for each distribution.
aic = c(GAU=AIC(x.gau, k=2), GAM=AIC(x.gam, k=2),
        BS=AIC(x.bs, k=2), WEI=AIC(x.wei, k=2))
bic = c(GAU=AIC(x.gau, k=log(nx)), GAM=AIC(x.gam, k=log(nx)),
        BS=AIC(x.bs, k=log(nx)), WEI=AIC(x.wei, k=log(nx)))

signif(cbind(AIC=aic, BIC=bic), 4)

#>      AIC  BIC
#> GAU 1495 1501
#> GAM 1499 1504
#> BS  1507 1512
#> WEI 1498 1505

post = exp(-0.5*(bic-1500))/sum(exp(-0.5*(bic-1500)))
cbind(signif(post, 2))

#> GAU 0.7600
#> GAM 0.1600
#> BS  0.0027
#> WEI 0.0740

## Generate a 95 % confidence interval on the 

xDATA = x

nb = 5000
percentile = rep(NA, nb)
for (jb in 1:nb)
{
  if (jb %% 100 == 0) {cat(jb, "of", nb, "\n")}
  x = sample(xDATA, size=nx, replace=TRUE)
  xb.gau = try(mle(negloglik.gau, method="Nelder-Mead",
                   start=list(mu=mean(x), sigma=sd(x))))
  xb.gam = try(mle(negloglik.gam, method="Nelder-Mead",
                   start=list(alpha=(mean(x)/sd(x))^2,
                              lambda=mean(x)/var(x))))
  xb.bs = try(mle(negloglik.bs, method="Nelder-Mead",
                  start=list(alpha=0.25, beta=30)))
  xb.wei = try(mle(negloglik.wei, method="Nelder-Mead",
                   start=list(xi=100, beta=2, eta=15)))
  if (any(c(class(xb.gau), class(xb.gam), class(xb.bs),
            class(xb.wei)) == "try-error")) {next} else {
                bic = c(GAU=AIC(x.gau, k=log(nx)),
                        GAM=AIC(x.gam, k=log(nx)),
                        BS=AIC(x.bs, k=log(nx)),
                        WEI=AIC(x.wei, k=log(nx)))
                ib = which.min(bic)
                percentile[jb] = switch(ib,
                          qnorm(0.001, mean=xb.gau@coef[1],
                                sd=xb.gau@coef[2]),
                          qgamma(0.001, alpha=xb.gam@coef[1],
                                 lambda=xb.gam@coef[2]),
                          qbs(0.001, alpha=xb.bs@coef[1],
                              beta=xb.bs@coef[2]),
                          xb.wei@coef[1] +
                          qweibull(0.001, beta=xb.wei@coef[2],
                                   eta=xb.wei@coef[3])) }
}

signif(quantile(percentile, probs=c(0.025, 0.975), na.rm=TRUE), 3)

#>  2.5% 97.5% 
#>  39.9 366.0
## R function by C.-M. Wang to compute the table value 
## for a prediction interval based on Table A.14 in 
## <a href="../section4/eda43.htm#Hahn"#>Hahn and Meeker (1991)</a#>

ospi <- function(n, p, m, alpha, nrun=500000) {

## Compute the factor r for constructing one-sided
## (1 - alpha)*100% prediction intervals:
## xbar + r * s to contain at least p out of m 
## future observations based on a random sample 
## of size n from a normal distribution using a 
## Monte Carlo method with nrun Monte Carlo samples.
## Use alpha=0.05.

   z1 = rnorm(nrun)/sqrt(n)
   V = sqrt(rchisq(nrun, n-1)/(n-1))
   z2i = matrix(rnorm(m*nrun), byrow=T, ncol=m)
   xij = apply((z2i-z1)/V, 1, function(x, q) sort(x)[q], m-p+1)
   rval = quantile(xij, alpha)
   rval
}

## Example:  Compute a lower prediction interval 
## that contains each of three future observations.
## n=101, m=p=3, alpha=0.05

r = ospi(101,3,3,0.05)
r
###>        5% 
###> -2.160811 

xbar = 1400.91
sdx = 391.32
xbar + r*sdx
###>       5% 
###> 555.3414 ##R commands and output:

## Input data.
x = c( 370, 1016, 1235, 1419, 1567, 1820,
       706, 1018, 1238, 1420, 1578, 1868,
       716, 1020, 1252, 1420, 1594, 1881,
       746, 1055, 1258, 1450, 1602, 1890,
       785, 1085, 1262, 1452, 1604, 1893,
       797, 1102, 1269, 1475, 1608, 1895,
       844, 1102, 1270, 1478, 1630, 1910,
       855, 1108, 1290, 1481, 1642, 1923,
       858, 1115, 1293, 1485, 1674, 1940,
       886, 1120, 1300, 1502, 1730, 1945,
       886, 1134, 1310, 1505, 1750, 2023,
       930, 1140, 1313, 1513, 1750, 2100,
       960, 1199, 1315, 1522, 1763, 2130,
       988, 1200, 1330, 1522, 1768, 2215,
       990, 1200, 1355, 1530, 1781, 2268,
      1000, 1203, 1390, 1540, 1782, 2440,
      1010, 1222, 1416, 1560, 1792)

## Generate initial plots of the data.
par(mfrow=c(2,2),bg=rgb(1,1,0.8))
dotchart(x,xlab="Polished Window Strength (ksi)")
boxplot (x,ylab="Polished Window Strength (ksi)")
hist    (x,ylab="Counts",xlab="Polished Window Strength (ksi)",main="")
plot(density(x),xlab="Polished Window Strength (ksi)",main="")


## Generate QQ-plot of the data.
par(mfrow=c(1,1),bg=rgb(1,1,0.8))
qqnorm(x, pch=20, col="Red")


## Plot 99 samples from the data and compare QQ-plots to actual data.
x.ave = mean(x); x.sd = sd(x)
nx = length(x)
nb = 99
u = qnorm(ppoints(nx))
xb = array(dim=c(nx,nb))
for (jb in 1:nb) {
   xb[,jb] = sort(qqnorm(rnorm(nx, mean=x.ave, sd=x.sd),
   plot=FALSE)$y)}
par(mfrow=c(1,1),bg=rgb(1,1,0.8))
zz = qqnorm(x, pch=20, col="Red")
matplot(u, xb, type="p", pch=21, col="Blue", add=TRUE)
points(zz$x,zz$y, pch=20, col="Red")



## Compare QQ-plots of the data for various distributions 
## using maximum likelihood estimation.
require(stats4)
negloglik.gau = function (mu, sigma) {
    if (sigma < 0) {return(Inf)} else {
    -sum(dnorm(x, mean=mu, sd=sigma, log=TRUE))}}
x.gau = mle(negloglik.gau, method="Nelder-Mead",
           start=list(mu=mean(x), sigma=sd(x)))
x.gau@coef

##>        mu     sigma 
##> 1400.8145  389.3003

negloglik.gam = function (alpha, lambda) {
    if (any(c(alpha, lambda) < 0)) {return(Inf)} else {
    -sum(dgamma(x, shape=alpha, rate=lambda, log=TRUE))}}
x.gam = mle(negloglik.gam, method="Nelder-Mead",
           start=list(alpha=(mean(x)/sd(x))^2,
           lambda=mean(x)/var(x)))
x.gam@coef

##>        alpha       lambda 
##> 11.851717840  0.008459428 
require(bs)
negloglik.bs = function (alpha, beta) {
    if (any(c(alpha, beta) < 0)) {return(Inf)} else {
    -sum(dbs(x, alpha, beta, log=TRUE))}}
x.bs = mle(negloglik.bs, method="Nelder-Mead",
           start=list(alpha=0.25, beta=30))
x.bs@coef

##>        alpha         beta 
##>    0.3100202 1336.7948970 

negloglik.wei = function (xi, beta, eta) {
    -sum(dweibull(x-xi, shape=beta, scale=eta, log=TRUE)) }
x.wei = mle(negloglik.wei, method="L-BFGS-B",
            lower=c(-Inf, 0, 0),
            start=list(xi=100, beta=2, eta=15))
x.wei@coef

##>          xi        beta         eta 
##>  181.154738    3.428001 1356.441176


## Plot overlaid density for each distribution.
xl = mean(x)-3*sd(x); xu=mean(x)+3*sd(x)
plot(density(x, from=xl, to=xu), ylim=c(0, 0.0012),main="")
curve(dnorm(x, mean=x.gau@coef[1], sd=x.gau@coef[2]),
      from=xl, to=xu, col="LightBlue", add=TRUE, lwd=2)
curve(dgamma(x, shape=x.gam@coef[1], rate=x.gam@coef[2]),
      from=xl, to=xu, col="Brown", add=TRUE, lwd=2)
curve(dbs(x, alpha=x.bs@coef[1], beta=x.bs@coef[2]),
      from=xl, to=xu, col="Red", add=TRUE, lwd=2)
curve(dweibull(x-x.wei@coef[1], shape=x.wei@coef[2],
      scale=x.wei@coef[3]),
      from=xl, to=xu, col="Purple", add=TRUE, lwd=2)
legend(1700, 0.0012, bty="n",
       legend=c("Data", "Gaussian", "Gamma",
                "Birnbaum-Saunders", "Weibull"), 
       lty=c(1,1,1,1,1),
       col=c("Black","LightBlue", "Brown", "Red", "Purple"))



## Generate QQ-plots for each distribution and overlay.
xy.gau = list(x=sort(qnorm(ppoints(x),
              mean=x.gau@coef[1], sd=x.gau@coef[2])),
              y=sort(x))
xy.gam = list(x=sort(qgamma(ppoints(x),
              shape=x.gam@coef[1], rate=x.gam@coef[2])),
              y=sort(x))
xy.bs = list(x=sort(qbs(ppoints(x),
             alpha=x.bs@coef[1], beta=x.bs@coef[2])),
             y=sort(x))
xy.wei = list(x=sort(x.wei@coef[1] + qweibull(ppoints(x),
              shape=x.wei@coef[2], scale=x.wei@coef[3])),
              y=sort(x))
plot(xy.gau, pch=15, col="LightBlue",
     xlab="Theoretical Quantiles",
     ylab="Sample Quantiles")
points(xy.gam, pch=16, col="Brown")
points(xy.bs, pch=17, col="Red")
points(xy.wei, pch=18, col="Purple")
legend(500, 2400, bty="n",
       legend=c("Gaussian", "Gamma",
       "Birnbaum-Saunders", "Weibull"), pch=c(15,16,17,18),
       col=c("LightBlue", "Brown", "Red", "Purple"))



## Compute AIC and BIC for each distribution.
aic = c(GAU=AIC(x.gau, k=2), GAM=AIC(x.gam, k=2),
        BS=AIC(x.bs, k=2), WEI=AIC(x.wei, k=2))
bic = c(GAU=AIC(x.gau, k=log(nx)), GAM=AIC(x.gam, k=log(nx)),
        BS=AIC(x.bs, k=log(nx)), WEI=AIC(x.wei, k=log(nx)))

signif(cbind(AIC=aic, BIC=bic), 4)

##>      AIC  BIC
##> GAU 1495 1501
##> GAM 1499 1504
##> BS  1507 1512
##> WEI 1498 1505

post = exp(-0.5*(bic-1500))/sum(exp(-0.5*(bic-1500)))
cbind(signif(post, 2))

##> GAU 0.7600
##> GAM 0.1600
##> BS  0.0027
##> WEI 0.0740

## Generate a 95 % confidence interval on the 

xDATA = x

nb = 5000
percentile = rep(NA, nb)
for (jb in 1:nb)
{
  if (jb %% 100 == 0) {cat(jb, "of", nb, "\n")}
  x = sample(xDATA, size=nx, replace=TRUE)
  xb.gau = try(mle(negloglik.gau, method="Nelder-Mead",
                   start=list(mu=mean(x), sigma=sd(x))))
  xb.gam = try(mle(negloglik.gam, method="Nelder-Mead",
                   start=list(alpha=(mean(x)/sd(x))^2,
                              lambda=mean(x)/var(x))))
  xb.bs = try(mle(negloglik.bs, method="Nelder-Mead",
                  start=list(alpha=0.25, beta=30)))
  xb.wei = try(mle(negloglik.wei, method="Nelder-Mead",
                   start=list(xi=100, beta=2, eta=15)))
  if (any(c(class(xb.gau), class(xb.gam), class(xb.bs),
            class(xb.wei)) == "try-error")) {next} else {
                bic = c(GAU=AIC(x.gau, k=log(nx)),
                        GAM=AIC(x.gam, k=log(nx)),
                        BS=AIC(x.bs, k=log(nx)),
                        WEI=AIC(x.wei, k=log(nx)))
                ib = which.min(bic)
                percentile[jb] = switch(ib,
                          qnorm(0.001, mean=xb.gau@coef[1],
                                sd=xb.gau@coef[2]),
                          qgamma(0.001, alpha=xb.gam@coef[1],
                                 lambda=xb.gam@coef[2]),
                          qbs(0.001, alpha=xb.bs@coef[1],
                              beta=xb.bs@coef[2]),
                          xb.wei@coef[1] +
                          qweibull(0.001, beta=xb.wei@coef[2],
                                   eta=xb.wei@coef[3])) }
}

signif(quantile(percentile, probs=c(0.025, 0.975), na.rm=TRUE), 3)

##>  2.5% 97.5% 
##>  39.9 366.0
## R function by C.-M. Wang to compute the table value 
## for a prediction interval based on Table A.14 in 
## <a href="../section4/eda43.htm#Hahn"#>Hahn and Meeker (1991)</a#>

ospi <- function(n, p, m, alpha, nrun=500000) {

## Compute the factor r for constructing one-sided
## (1 - alpha)*100% prediction intervals:
## xbar + r * s to contain at least p out of m 
## future observations based on a random sample 
## of size n from a normal distribution using a 
## Monte Carlo method with nrun Monte Carlo samples.
## Use alpha=0.05.

   z1 = rnorm(nrun)/sqrt(n)
   V = sqrt(rchisq(nrun, n-1)/(n-1))
   z2i = matrix(rnorm(m*nrun), byrow=T, ncol=m)
   xij = apply((z2i-z1)/V, 1, function(x, q) sort(x)[q], m-p+1)
   rval = quantile(xij, alpha)
   rval
}

## Example:  Compute a lower prediction interval 
## that contains each of three future observations.
## n=101, m=p=3, alpha=0.05

r = ospi(101,3,3,0.05)
r
###>        5% 
###> -2.160811 

xbar = 1400.91
sdx = 391.32
xbar + r*sdx
###>       5% 
###> 555.3414 #R commands and output:


## A function to generate 13 random repair times 
## and plot the results follows.
## The user provides N, a, and b.

powersim=function(N,a,b){

  U=runif(N)
  Y= rep(NA,N)
  Y[1]= ((-1/a)* log(U[1]) ) ^(1/b)
  for ( i in 2:N){
    Y[i]= ( (Y[i-1])^b - (1/a)* (log(U[i]) ) )^ (1/b) 
  }
  plot(Y, 1:N,xlab="Failure Times", ylab="Failure Number")
  return(list(Y = Y))
}

## Run the function.
ex = powersim(13,.2,.4)

ex$Y

#>  [1]     7.129044    62.825997    79.998949   456.669847   600.635556
#>  [6]   982.997682  5892.529347  6242.845270  7786.899615 10462.573861
#> [11] 11941.892215 12570.738837 25737.514277
#R commands and output:


## Example 1

## Create variables.
failnum = c(1:8)
age = c(33,76,145,347,555,811,1212,1499)
MTBF = age/failnum

## Generate Duane plot.
plot(age, MTBF, log = "xy", xaxt="n", yaxt="n", pch=19,
     col="blue", xlab="System Age", ylab="Cumulative MTBF") 
axis(1, at=(seq(0,10000,100)))
axis(2, at=(seq(0,200,10)))


## Example 2

## A function to generate 13 random repair times 
## and plot the results follows.
## The user provides N, a, and b.

powersim=function(N,a,b){

U=runif(N)

Y= rep(NA,N)

Y[1]= ((-1/a)* log(U[1]) ) ^(1/b)

for ( i in 2:N){
  Y[i]= ( (Y[i-1])^b - (1/a)* (log(U[i]) ) )^ (1/b) 
}

plot(Y, 1:N,xlab="Failure Times", ylab="Failure Number")

return(list(Y = Y))}


## Run the function.
ex = powersim(13,.2,.4)

ex$Y

#>  [1]     7.129044    62.825997    79.998949   456.669847   600.635556
#>  [6]   982.997682  5892.529347  6242.845270  7786.899615 10462.573861
#> [11] 11941.892215 12570.738837 25737.514277


## Generate Duane plot.
FAILNUM = 1:13
FAILTIME = ex$Y
MCUM = FAILTIME/FAILNUM 

plot(log10(FAILTIME),log10(MCUM), xlab='log10(Failure Time)', 
     ylab='log10 (Cum MTBF)')


#R commands and output:

## Input data and generate plotting variables.
## x = time of failure
## y = ln(1/(1-F(t))
x = c(54, 187, 216, 240, 244, 335, 361, 373, 375, 386)
n = 20
fnum = c(1:length(x))
Ft = (fnum-0.3)/(n+0.4)
y = log(1/(1-Ft))

## Print y values.
y
#> [1] 0.03491627 0.08701138 0.14197026 0.20012618 0.26187419 0.32768741
#> [7] 0.39813907 0.47393291 0.55594606 0.64529116

## Generate probability plot.
plot(x,y, xlab="Time", ylab="ln(1/(1-F(t)))", log="xy",
     type="o", pch=19, col="blue")

## Compute slope of line fit to plotted data.
xx=log10(x)
yy=log10(y)
z = lm(yy ~ xx)
coef(z)

#>(Intercept)          xx 
#>  -4.116536    1.457519 

## Another way to generate the Weibull Probability Plot using
## functions already available in R.
p = ppoints(x, a=0.3)
plot(x, -log(1-p), log="xy", type="o", col="blue",
     xlab="Time", ylab="ln(1/(1-F(t)))")
#R commands and output:

## Input data and compute the cumulative hazard.
time = c( 37, NA, 73, NA, 132, 195, NA, 222, 248, NA)
fail = c(1, 0, 1, 0, 1, 1, 0, 1, 1, 0)
revrank = c(length(fail):1)
haz = fail/revrank
cumhaz = cumsum(haz)

## Select failing cases for plotting.
df = data.frame(time, fail, cumhaz)
z = subset(df, fail==1)

## Generate cumulative hazard plot for exponential distribution.
plot(z$time, z$cumhaz, type="o", pch=19, col="blue",
     xlab="Time", ylab="Cumulative Hazard",
     main="Exponential Distribution")

## Generate cumulative hazard plot for the Weibull distribution.
plot(z$time, z$cumhaz, type="o", pch=19, col="blue", log="xy",
     xlab="Time", ylab="Cumulative Hazard", 
     main="Weibull Distribution")

## Compute Weibull parameter estimates.
lm(log10(z$cumhaz)~log10(z$time))

###> Call:
###> lm(formula = log10(z$cumhaz) ~ log10(z$time))
###> 
###> Coefficients:
###>   (Intercept)  log10(z$time)  
###>        -3.025          1.271#R commands and output:

## Input failure times.
x = c(5, 40, 43, 175, 389, 712, 747, 795, 1299, 1478)
nfail = length(x)

## Cumulative plot.
plot(x,1:nfail, xlim=c(0,1500), main="Cumulative Plot", 
     xlab="System Age", ylab="No. Repairs", 
     type="o", col="blue", pch=19)

## Compute interarrival time.
x0 = c(0, x[1:(length(x)-1)])
interarrival = x-x0

## Interarrival time plot.
plot(1:nfail, interarrival, xlab="Failure Number", 
     ylab="Interarrival Time",
     main = "Interarrival Time versus Failure Number", 
     col="red", pch=17)

## Reciprocal interarrival time plot.
plot(1:nfail, 1/interarrival, xlab="Failure Number",
     ylab="Reciprocal Interarrival Time", 
     main="Reciprocal Interarrival Times",
     col="blue", pch=19)

## Duane plot.
MCUM = x / (1:nfail)
plot(x, MCUM, log="xy", xlab="Failure Time",
     ylab="Cumulative Hazard",
     main="Duane Plot", 
     col="red", pch=18,
     panel.first=grid(equilogs=FALSE)) 
#R commands and output:

## Input temperature data, number of units, and cell data.
temp = c(85, 105, 125)
nu = c(100, 50, 25)
cell1 = c(401, 428, 695, 725, 738)
cell2 = c(171, 187, 189, 266, 275, 285, 301, 302, 305, 316, 317, 
          324, 349, 350, 386, 405, 480, 493, 530, 534, 536, 567, 
          589, 598, 599, 614, 620, 650, 668, 685, 718, 795, 854, 
          917, 926)
cell3 = c(24, 42, 92, 93, 141, 142, 143, 159, 181, 188, 194, 199, 
          207, 213, 243, 256, 259, 290, 294, 305, 392, 454, 502, 696)

## Apply ln function to cell data.
y1 = log(cell1)
y2 = log(cell2)
y3 = log(cell3)

## Generate lognormal probability plot using procedure from 8.2.2.1.
pos1 = 1:length(cell1)
pos2 = 1:length(cell2)
pos3 = 1:length(cell3)
pos1 = (pos1-0.3)/(nu[1]+0.4)
pos2 = (pos2-0.3)/(nu[2]+0.4)
pos3 = (pos3-0.3)/(nu[3]+0.4)
x1 = qnorm(pos1)
x2 = qnorm(pos2)
x3 = qnorm(pos3)

## Generate lognormal probability plot for each cell
## and plot the curves on the same plot.
plot(c(x1,x2,x3), c(y1,y2,y3), type="n", 
     xlab="Theoretical Quantiles", ylab="ln Time",
     main="PROBABILITY PLOT OF TEMPERATURE CELLS")    
lines(x1,y1, col="blue")
lines(x2,y2, col="blue")
lines(x3,y3, col="blue")

## Compute Ao, the ln T50 estimate, and A1, the cell sigma estimate.
z1 = lsfit(x1,y1)
z2 = lsfit(x2,y2)
z3 = lsfit(x3,y3)

## Save intercepts from the three fits. 
YARRH = c(z1$coef[1], z2$coef[1], z3$coef[1])
YARRH

#> Intercept Intercept Intercept 
#>  8.167866  6.415268  5.319294

## Compute 11605/(temp+273.16) for three cell temperatures.
XARRH = 11605/(temp + 273.15)
XARRH

#> [1] 32.40262 30.68888 29.14731


## Plot Arrhenius cell T50's.
plot(XARRH, YARRH, type="o", ylab="ln T50", xlab="11605/(t+273.16)",
     main="ARRHENIUS PLOT", pch=19, col="red")

## Fit linear model.
z = lm( YARRH~XARRH, 
    weights=c(length(cell1), length(cell2), length(cell3)))
coef(z)

#> (Intercept)       XARRH 
#> -18.3113408   0.8084907 

## Estimate A.
A = exp(z$coef[1]) 
names(A) <- NULL
A

#> (Intercept) 
#>   1.115542e-08 

## Estimate delta H.
dH = z$coef[2]
names(dH) <- NULL
dH

#> [1] 0.8084907

## Compute acceleration between 85 C and 125 C.
exp(dH*11605*(1/(temp[1]+273.16) - 1/(temp[3]+273.16)))

#> [1] 13.89814

## Example of fitting a model with two stresses, 
## assuming Y, X1 ,X2  data vectors already exist. 
##lm(Y ~ X1 + X2)
#R commands and output:

## Load survival package.
require(survival)

## Input data for Cell 1 - 85 degrees.
cell85 = c(401, 428, 695, 725, 738)
NC85 = 100

## Create survival object.
y85 = Surv(c(cell85, rep(1000, NC85-length(cell85))), 
           c(rep(1,length(cell85)), rep(0, NC85-length(cell85)))
          )

## Generate survival curve (Kaplan-Meier).
ys85 = survfit(y85 ~ 1, type="kaplan-meier")
summary(ys85)

#> Call: survfit(formula = y85 ~ 1, type = "kaplan-meier")
#> 
#>  time n.risk n.event survival std.err lower 95% CI upper 95% CI
#>   401    100       1     0.99 0.00995        0.971        1.000
#>   428     99       1     0.98 0.01400        0.953        1.000
#>   695     98       1     0.97 0.01706        0.937        1.000
#>   725     97       1     0.96 0.01960        0.922        0.999
#>   738     96       1     0.95 0.02179        0.908        0.994

plot(ys85, xlab="Hours", ylab="Survival Probability", col="red")

## Lognormal Fit.
yl85 = survreg(y85 ~ 1, dist="lognormal")
summary(yl85)

#> Call:
#> survreg(formula = y85 ~ 1, dist = "lognormal")
#>             Value Std. Error      z        p
#> (Intercept) 8.891      0.890  9.991 1.67e-23
#> Log(scale)  0.192      0.406  0.473 6.36e-01
#> 
#> Scale= 1.21 
#> 
#> Log Normal distribution
#> Loglik(model)= -53.4   Loglik(intercept only)= -53.4
#> Number of Newton-Raphson Iterations: 10 
#> n= 100 


## Input data for Cell 2 - 105 degrees.
NC105 = 50
cell105 = c(171, 187, 189, 266, 275, 285, 301, 302, 305, 
            316, 317, 324, 349, 350, 386, 405, 480, 493, 
            530, 534, 536, 567, 589, 598, 599, 614, 620, 
            650, 668, 685, 718, 795, 854, 917,  926)

## Create survival object.
y105= Surv(c(cell105, rep(1000, NC105-length(cell105))), 
           c(rep(1,length(cell105)), rep(0,NC105-length(cell105))))

## Generate survival curve (Kaplan-Meier).
ys105 = survfit(y105 ~ 1, type="kaplan-meier")
summary(ys105)

#> Call: survfit(formula = y105 ~ 1, type = "kaplan-meier")
#> 
#>  time n.risk n.event survival std.err lower 95% CI upper 95% CI
#>   171     50       1     0.98  0.0198        0.942        1.000
#>   187     49       1     0.96  0.0277        0.907        1.000
#>   189     48       1     0.94  0.0336        0.876        1.000
#>   266     47       1     0.92  0.0384        0.848        0.998
#>   275     46       1     0.90  0.0424        0.821        0.987
#>   285     45       1     0.88  0.0460        0.794        0.975
#>   301     44       1     0.86  0.0491        0.769        0.962
#>   302     43       1     0.84  0.0518        0.744        0.948
#>   305     42       1     0.82  0.0543        0.720        0.934
#>   316     41       1     0.80  0.0566        0.696        0.919
#>   317     40       1     0.78  0.0586        0.673        0.904
#>   324     39       1     0.76  0.0604        0.650        0.888
#>   349     38       1     0.74  0.0620        0.628        0.872
#>   350     37       1     0.72  0.0635        0.606        0.856
#>   386     36       1     0.70  0.0648        0.584        0.839
#>   405     35       1     0.68  0.0660        0.562        0.822
#>   480     34       1     0.66  0.0670        0.541        0.805
#>   493     33       1     0.64  0.0679        0.520        0.788
#>   530     32       1     0.62  0.0686        0.499        0.770
#>   534     31       1     0.60  0.0693        0.478        0.752
#>   536     30       1     0.58  0.0698        0.458        0.734
#>   567     29       1     0.56  0.0702        0.438        0.716
#>   589     28       1     0.54  0.0705        0.418        0.697
#>   598     27       1     0.52  0.0707        0.398        0.679
#>   599     26       1     0.50  0.0707        0.379        0.660
#>   614     25       1     0.48  0.0707        0.360        0.641
#>   620     24       1     0.46  0.0705        0.341        0.621
#>   650     23       1     0.44  0.0702        0.322        0.602
#>   668     22       1     0.42  0.0698        0.303        0.582
#>   685     21       1     0.40  0.0693        0.285        0.562
#>   718     20       1     0.38  0.0686        0.267        0.541
#>   795     19       1     0.36  0.0679        0.249        0.521
#>   854     18       1     0.34  0.0670        0.231        0.500
#>   917     17       1     0.32  0.0660        0.214        0.479
#>   926     16       1     0.30  0.0648        0.196        0.458

plot(ys105, xlab="Hours", ylab="Survival Probability", col="green")

## Lognormal Fit
yl105 = survreg(y105 ~ 1, dist="lognormal")
summary(yl105)

#> Call:
#> survreg(formula = y105 ~ 1, dist = "lognormal")
#>              Value Std. Error     z       p
#> (Intercept)  6.470      0.108 60.14 0.00000
#> Log(scale)  -0.336      0.129 -2.60 0.00923
#> 
#> Scale= 0.715 
#> 
#> Log Normal distribution
#> Loglik(model)= -265.2   Loglik(intercept only)= -265.2
#> Number of Newton-Raphson Iterations: 5 
#> n= 50


## Input data for Cell 3 - 125 degrees.
NC125 = 25
cell125 = c(24, 42, 92, 93, 141, 142, 143, 159, 181, 188, 194, 
            199, 207, 213, 243, 256, 259, 290, 294, 305, 392, 
            454, 502 ,696)

## Create survival object.
y125 = Surv(c(cell125, rep(1000, NC125-length(cell125))), 
            c(rep(1,length(cell125)), rep(0,NC125-length(cell125))))

## Generate survival curve (Kaplan-Meier).
ys125 = survfit(y125 ~ 1, type="kaplan-meier")
summary(ys125)

#> Call: survfit(formula = y125 ~ 1, type = "kaplan-meier")
#> 
#>  time n.risk n.event survival std.err lower 95% CI upper 95% CI
#>    24     25       1     0.96  0.0392      0.88618        1.000
#>    42     24       1     0.92  0.0543      0.81957        1.000
#>    92     23       1     0.88  0.0650      0.76141        1.000
#>    93     22       1     0.84  0.0733      0.70791        0.997
#>   141     21       1     0.80  0.0800      0.65761        0.973
#>   142     20       1     0.76  0.0854      0.60974        0.947
#>   143     19       1     0.72  0.0898      0.56386        0.919
#>   159     18       1     0.68  0.0933      0.51967        0.890
#>   181     17       1     0.64  0.0960      0.47698        0.859
#>   188     16       1     0.60  0.0980      0.43566        0.826
#>   194     15       1     0.56  0.0993      0.39563        0.793
#>   199     14       1     0.52  0.0999      0.35681        0.758
#>   207     13       1     0.48  0.0999      0.31919        0.722
#>   213     12       1     0.44  0.0993      0.28275        0.685
#>   243     11       1     0.40  0.0980      0.24749        0.646
#>   256     10       1     0.36  0.0960      0.21346        0.607
#>   259      9       1     0.32  0.0933      0.18071        0.567
#>   290      8       1     0.28  0.0898      0.14934        0.525
#>   294      7       1     0.24  0.0854      0.11947        0.482
#>   305      6       1     0.20  0.0800      0.09132        0.438
#>   392      5       1     0.16  0.0733      0.06517        0.393
#>   454      4       1     0.12  0.0650      0.04151        0.347
#>   502      3       1     0.08  0.0543      0.02117        0.302
#>   696      2       1     0.04  0.0392      0.00586        0.273

plot(ys125, xlab="Hours", ylab="Survival Probability", col="blue")

## Lognormal Fit.
yl125 = survreg(y125 ~ 1, dist="lognormal")
summary(yl125)

#> Call:
#> survreg(formula = y125 ~ 1, dist = "lognormal")
#>             Value Std. Error     z         p
#> (Intercept)  5.33      0.163 32.82 3.42e-236
#> Log(scale)  -0.21      0.146 -1.44  1.51e-01
#> 
#> Scale= 0.81 
#> 
#> Log Normal distribution
#> Loglik(model)= -156.5   Loglik(intercept only)= -156.5
#> Number of Newton-Raphson Iterations: 5 
#> n= 25


## Plot three survival curves on the same graph.
plot(ys85, xlab="Hours", ylab="Survival Probability", col='red')
points(ys85$time, ys85$surv, col='red', pch=20)

points(ys105$time, ys105$surv, col='green', pch=1)
lines(ys105$time, ys105$surv, col='green')
lines(ys105$time, ys105$upper, col='green', lty=2)
lines(ys105$time, ys105$lower, col='green', lty=2)

points(ys125$time, ys125$surv, col='blue', pch=15, cex=0.9)
lines(ys125$time, ys125$surv, col='blue')
lines(ys125$time, ys125$upper, col='blue', lty=2)
lines(ys125$time, ys125$lower, col='blue', lty=2)

legend('bottomleft', legend=c(85,105,125), lty=c(1,1,1),
       pch=c(20,1,15), cex=0.9, col=c('red','green','blue'))


## Fit the overall Arrhhenius model.
y.All = rbind(y85, y105, y125)
y.all = Surv(y.All[,1], y.All[,2])
k = 8.617e-5
TempC = c(rep(85,NC85), rep(105,NC105), rep(125,NC125))
T = TempC + 273.16
lkT = 1/(k*T)

ylkT = survreg(y.all ~ lkT, dist="lognormal")
summary(ylkT)

#> Call:
#> survreg(formula = y.all ~ lkT, dist = "lognormal")
#>               Value Std. Error     z        p
#> (Intercept) -19.906     2.3204 -8.58 9.60e-18
#> lkT           0.863     0.0761 11.34 7.89e-30
#> Log(scale)   -0.259     0.0928 -2.79 5.32e-03
#> 
#> Scale= 0.772 
#> 
#> Log Normal distribution
#> Loglik(model)= -476.7   Loglik(intercept only)= -551
#>         Chisq= 148.58 on 1 degrees of freedom, p= 0 
#> Number of Newton-Raphson Iterations: 6 
#> n= 175 


## Perform likelihood ratio test to see if the Arrhenius
## model is better than the individual cell fits.

## Combine ln likelihood values for three model.
lnL1 = yl85$loglik[1] + yl105$loglik[1] + yl125$loglik[1]
lnL1

#> [1] -475.1119

## Save ln likelihood for Arrhenius model (acceleration model).
lnL0 = ylkT$loglik[2]
lnL0

#> [1] -476.7089

## Compute -2 ln likelihood
lr = -2*(lnL0 - lnL1)
lr

#> [1] 3.194015

## Chi-square critical value.
qchisq(0.95,3)

#> [1] 7.814728

## Chi-square p-value.
1-pchisq(lr,3)

#> [1] 0.3626682

##R commands and output:

## Input data.
DEG = c(0.87, 0.33, 0.94, 0.72, 0.66, 1.48, 0.96, 2.91, 1.98, 
       0.99, 2.81, 2.13, 5.67, 4.28, 2.14, 1.41, 3.61, 2.13,
       4.36, 6.91, 2.47, 8.99, 5.72, 9.82, 17.37, 5.71, 17.69,
       11.54, 19.55, 34.84, 24.58, 9.73, 4.74, 23.61, 10.90,
       62.02, 24.07, 11.53, 58.21, 27.85, 124.10, 48.06, 
       23.72, 117.20, 54.97)

TEMP = c(rep(65,15), rep(85,15), rep(105,15))

TIME = rep(c(200, 200, 200, 200, 200, 
             500, 500, 500, 500, 500, 
             1000, 1000, 1000, 1000, 1000), 3)

## Create variables for fitting.
YIJK = log(30) - (log(DEG) - log(TIME)) 
XIJK = 100000/(8.617*(TEMP + 273.16)) 

## Fit model.
lin.fit= lm(YIJK ~ XIJK)
summary(lin.fit)

#> Call:
#> lm(formula = YIJK ~ XIJK)
#> 
#> Residuals:
#>      Min       1Q   Median       3Q      Max 
#> -0.82806 -0.39392 -0.04028  0.35714  1.12534 
#> 
#> Coefficients:
#>              Estimate Std. Error t value Pr(#>|t|)    
#> (Intercept) -18.94337    1.83343  -10.33 3.17e-13 ***
#> XIJK          0.81877    0.05641   14.52  < 2e-16 ***
#> ---
#> Signif. codes:  0 ?***? 0.001 ?**? 0.01 ?*? 0.05 ?.? 0.1 ? ? 1 
#> 
#> Residual standard error: 0.5611 on 43 degrees of freedom
#> Multiple R-squared: 0.8305,     Adjusted R-squared: 0.8266 
#> F-statistic: 210.7 on 1 and 43 DF,  p-value: < 2.2e-16 
#R commands and output:

## The qchisq function requires left tail probability inputs. 
## LOWER = T*2 / qchisq(1-alpha/2, df=2*(r+1))
## UPPER = T*2 / qchisq(alpha/2, df=2*r)

## Example.
LOWER=1600/ qchisq(0.95, df=6)
LOWER

###> [1] 127.0690

UPPER=1600 / qchisq(.05,df=4)
UPPER

###> [1] 2251.229
#R commands and output:

## Enter data.
x=c(5, 40, 43, 175, 389, 712, 747, 795, 1299, 1478 )
r=length(x)
T=1500


## Compute aHat, bHat, MTBF, ML, and MU.

BetaHat = 1-(r-1)/( sum(log(T/x)))
BetaHat

###> [1] 0.516494

aHat = r/(T^(1-BetaHat))
aHat

###> [1] 0.2913003

bHat = 1-BetaHat
bHat

###> [1] 0.483506

MTBF = T/(r*bHat)
MTBF

###> [1] 310.234


## Compute 80 % confidence interval for MTBF.
alpha = 0.2
za = qnorm(1-alpha/2)
za

###> [1] 1.281552

ML = MTBF*r*(r-1)/(r + (za^2)/4 + sqrt(r*(za^2)/2 + (za^4)/16))^2
ML

###> [1] 157.7138

MU = MTBF*r*(r-1)/(r - za*sqrt(r/2))^2
MU

###> [1] 548.5566
