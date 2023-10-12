library(gridExtra)
library(tidyverse)
library(stringr)
dataE = read.csv("nlel_xv_rep_all.txt",header=T,sep=",", row.names = NULL)
colnames(dataE) = c("method","t","energy_frac","rxdim","rvdim","nldim","q","nqp","time","errx","errv")
dataE= as_tibble(dataE)

dataE = dataE %>% mutate(Eres = factor(str_count(as.character(energy_frac),"9")),
                         energy_frac = paste(as.character(energy_frac), sprintf("(%d)",Eres),sep=" "),
                         nqp = case_when(method=="EQP"~nldim,.default =  nqp),
                         q= case_when(method=="EQP"~NA,.default =  q), 
                         nldim = case_when(method=="EQP"~NA,.default =  nldim) )
dataE = dataE %>% pivot_longer(c(errx,errv),names_to = "errorType",values_to="error")



plot.viridis <-function(dataset, x='time'){
  xlab = ifelse(x=='time', "Wall clock time", "Number of Quadrature Points" )
  yticks = outer(c(1:10),(10^(as.integer(min(log10(dataset$error),na.rm = T)):as.integer(max(log10(dataset$error),na.rm = T))-1)))
  p= dataset %>% mutate( across(energy_frac,factor))%>%
    ggplot(aes(x=x, y=(error),color=energy_frac)) +
    geom_point(size=1) +  geom_line(aes(group=energy_frac)) +
    ylab("Relative L2 Error")+ 
    theme_bw()+
    scale_color_viridis_d()+
    scale_y_log10(limits=c(10^(as.integer(min(log10(dataset$error),na.rm = T))-1),10^(as.integer(max(log10(dataset$error),na.rm = T)))),labels=fancy_scientific,
                  minor_breaks=yticks) +
    labs(color="Eres")+
    theme(text = element_text(family = "Times New Roman"),
          
          axis.text = element_text(size = 10),
          axis.title = element_text(size = 15), 
          legend.text = element_text(size = 12)) + xlab(xlab) + facet_grid(errorType ~method)
  return(p)
}
plot.viridis(dataE %>% #filter(errorType == 'errx') %>%
               mutate(x=nqp, energy_frac=factor(Eres),errorType=case_when(errorType=="errx"~"Position",.default = "Velocity")),
             x='nqp')
plot.viridis(dataE %>% #filter(errorType == 'errx') %>%
               mutate( energy_frac=factor(Eres), x=time, errorType=case_when(errorType=="errx"~"Position",.default = "Velocity")),
             x='time')

plot.fancy <-function(dataset,x='time', pareto=T){
  xlab = ifelse(x=='time', "Wall clock time", "Number of Quadrature Points" )
  yticks = outer(c(1:10),(10^(as.integer(min(log10(dataset$error),na.rm = T)):as.integer(max(log10(dataset$error),na.rm = T))-1)))
  p = ggplot() + 
    #geom_point(aes(shape=energy_frac),size=2) + 
    geom_point(data = dataset %>% filter(method=='EQP'),aes(x=x,y=(error), color=method))+
    geom_point(data = dataset %>% filter(method!='EQP'),aes(x=x,y=(error), color=method), size=0.5)+
    xlab(xlab) +
    ylab("Relative L2 Error")+ 
    theme_bw()+
    scale_y_log10(limits=c(10^(as.integer(min(log10(dataset$error),na.rm = T))-1),10^(as.integer(max(log10(dataset$error),na.rm = T)))),
                  labels=fancy_scientific, minor_breaks=yticks) +
    labs(color= "Methods", shape = "Energy Fraction", linewidth=" ")+
    theme(text = element_text(family = "Times New Roman"),
          
          axis.text = element_text(size = 10),
          axis.title = element_text(size = 15), 
          legend.text = element_text(size = 12)) + facet_grid(errorType~Eres)
  if(pareto){
    xticks = outer(c(1:10),(10^(as.integer(min(log10(dataset$x))):as.integer(max(log10(dataset$x)))-1)))
    p= p+geom_line(data=dataset%>%filter(pareto==T)%>%arrange(x), aes(x,y,linewidth="overall Pareto front"),color='darkgray',alpha=0.5)+
      scale_x_log10(limits=c(10^(as.integer(min(log10(dataset$x)))-1),2*10^(as.integer(max(log10(dataset$x))))),labels=fancy_scientific,
                    minor_breaks=xticks) 
  }else{
    p = p+geom_line(data = dataset %>% filter(method !='EQP'),aes(x=x,y=(error), color=method))
  }
  return(p)
}

plot.fancy(dataE %>%
             mutate( energy_frac=factor(Eres), x=nqp, errorType=case_when(errorType=="errx"~"Position",.default = "Velocity")),
           x='nqp', pareto=F)


plot.fancy(dataE %>% #filter( q ==200 | method=="EQP" ) %>%
             mutate( energy_frac=factor(Eres), x=time, errorType=case_when(errorType=="errx"~"Position",.default = "Velocity")),
           x='time', pareto=F)

## make pareto front
dataE= dataE %>%mutate(paretoX=FALSE, paretoV=FALSE)
subX = dataE %>% filter(errorType=='errx' & method !='EQP')
paretoX= subX %>% dplyr::select(time,error) %>% filter(!is.na(time)) %>% mutate(error = round(log10(error),3), time = round(log10(time),3))
for(i in 1:nrow(paretoX)){
  subX$paretoX[i] = sum((apply(paretoX %>% mutate(time = time-time[i], error=error-error[i])<= 0,1,sum)==2)[-i])==0
}
subV = dataE %>% filter(errorType=='errv'& method !='EQP')
paretoV= subV %>% dplyr::select(time,error) %>% filter(!is.na(time)) %>% mutate(error = round(log10(error),3), time = round(log10(time),3))
for(i in 1:nrow(paretoV)){
  subV$paretoV[i] = sum((apply(paretoV %>% mutate(time = time-time[i], error=error-error[i])<= 0,1,sum)==2)[-i])==0
}
dataE = rbind(dataE %>% filter(method =='EQP'), subV, subX)

plot.fancy(dataE %>% filter(method=='EQP' | paretoX | paretoV) %>%
             mutate( energy_frac=factor(Eres), x=time, errorType=case_when(errorType=="errx"~"Position",.default = "Velocity")),
           x='time', pareto=F)





plot.fancy0 <-function(dataset,x='time', pareto=T){
  xlab = ifelse(x=='time', "Wall clock time", "Number of Quadrature Points" )
  yticks = outer(c(1:10),(10^(as.integer(min(log10(dataset$error))):as.integer(max(log10(dataset$error)))-1)))
  p = ggplot(dataset,aes(x=x,y=(error), color=method)) + 
    geom_point(aes(shape=energy_frac),size=2) + 
    xlab(xlab) +
    ylab("Relative L2 Error")+ 
    theme_bw()+
    scale_y_log10(limits=c(10^(as.integer(min(log10(dataset$error)))-1),10^(as.integer(max(log10(dataset$error))))),
                  labels=fancy_scientific, minor_breaks=yticks) +
    labs(color= "Methods", shape = "Energy Fraction", linewidth=" ")+
    theme(text = element_text(family = "Times New Roman"),
          
          axis.text = element_text(size = 10),
          axis.title = element_text(size = 15), 
          legend.text = element_text(size = 12)) + facet_grid(~errorType)
  if(pareto){
    xticks = outer(c(1:10),(10^(as.integer(min(log10(dataset$x))):as.integer(max(log10(dataset$x)))-1)))
    p= p+geom_line(data=dataset%>%filter(pareto==T)%>%arrange(x), aes(x,y,linewidth="overall Pareto front"),color='darkgray',alpha=0.5)+
      scale_x_log10(limits=c(10^(as.integer(min(log10(dataset$x)))-1),2*10^(as.integer(max(log10(dataset$x))))),labels=fancy_scientific,
                    minor_breaks=xticks) 
  }else{
    p = p+geom_line(aes(group=method))
  }
  return(p)
}


