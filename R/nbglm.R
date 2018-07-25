#' @useDynLib nbglm
#' @importFrom Rcpp sourceCpp
NULL

#'@export

"nbglm" <- function(form, data, weights=NULL, offset=NULL, mustart=NULL, control){
    X <- stats::model.matrix(form,data)
    t1 <- stats::model.frame(form,data)
    y <- stats::model.response(t1)
    # if(is.null(offset)) offset <- stats::model.offset(t1)
    if(is.null(offset)) offset <- rep(0,length(y))
    if(is.null(weights)) weights <- rep(1,length(y))
    gradient <- rep(0,ncol(X)+1)
    if(is.null(mustart)){ pars <- gradient+1}else{pars <- mustart}
    fitted.values <- rep(0,length(y))

    logl <- .Call("Neg_Bin",pars,X,y,weights,offset,gradient,fitted.values,PACKAGE="ecomix")
    vcov <- 0
    se <- rep(0,length(pars))
    if(control$calculate_hessian_cpp) {
      calc_deriv <- function(p){
        gradient <- rep(0,length(pars))
        ll <- .Call("Neg_Bin_Gradient",p,X,y,weights,offset,gradient,PACKAGE="ecomix")
        return(gradient)
      }
      hes <- numDeriv::jacobian(calc_deriv,pars)
      dim(hes) <- rep(length(pars),2)
      vcov <- try(solve(hes))
      se <- try(sqrt(diag(vcov)))
      colnames(vcov) <- rownames(vcov) <- c("theta",colnames(X))
    }
    names(pars) <- names(se) <- names(gradient) <- c("theta",colnames(X))

    return(list(logl=logl,coef=pars[-1],theta=pars[1],se=se[-1],se.theta=se[1],fitted=fitted.values,gradient=gradient,vcov=vcov))
  }