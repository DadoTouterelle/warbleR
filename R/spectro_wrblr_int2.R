#internal warbleR function, not to be called by users. It is a modified version of seewave::spectro 
# that allows to plot spectrograms without resetting the graphic device, which is useful for multipannel figures. It also allow using image() 
# which substantially increases speed (although makes some options unavailable)
#last modification on feb-27-2019 (MAS)
spectro_wrblr_int2 <- function(wave, f, wl = 512, wn = "hanning", zp = 0, ovlp = 0, 
                             complex = FALSE, norm = TRUE, fftw = FALSE, dB = "max0", 
                             dBref = NULL, plot = TRUE, grid = TRUE, 
                             cont = FALSE, collevels = NULL, palette = spectro.colors, 
                             contlevels = NULL, colcont = "black", colbg = "white", colgrid = "gray", 
                             colaxis = "black", collab = "black", cexlab = 1, cexaxis = 1, 
                             tlab = "Time (s)", flab = "Frequency (kHz)", alab = "Amplitude", 
                             scalelab = "Amplitude\n(dB)", main = NULL, scalefontlab = 1, 
                             scalecexlab = 0.75, axisX = TRUE, axisY = TRUE, tlim = NULL, 
                             trel = TRUE, flim = NULL, flimd = NULL, widths = c(6, 1), 
                             heights = c(3, 1), oma = rep(0, 4), listen = FALSE, fast.spec = FALSE, 
                             rm.zero = FALSE, amp.cutoff = NULL, X = NULL, palette.2 = reverse.topo.colors, bx = TRUE, add = FALSE, collev.min = NULL) 
{
  if (!is.null(dB) && all(dB != c("max0", "A", "B", "C", "D"))) 
    stop("'dB' has to be one of the following character strings: 'max0', 'A', 'B', 'C' or 'D'")
  sel.tab <- X
  
  if (is.list(palette)) palette <- unlist(palette[[1]])
  if (is.null(palette)) palette <- spectro.colors  
  if (!is.function(palette)) palette <- get(palette)
    
  if (is.null(collevels) & !is.null(collev.min))
    collevels <- seq(collev.min, 0, 1)
  
    if (!is.null(sel.tab)) fast.spec <- TRUE 
  
  if (complex & norm) {
    norm <- FALSE
    warning("\n'norm' was turned to 'FALSE'")
  }
  if (complex & !is.null(dB)) {
    dB <- NULL
    warning("\n'dB' was turned to 'NULL'")
  }
  input <- seewave::inputw(wave = wave, f = f)
  
  wave <- input$w
  
  f <- input$f
  rm(input)
  if (!is.null(tlim)) 
    wave <- cutw(wave, f = f, from = tlim[1], to = tlim[2])
  if (!is.null(flimd)) {
    mag <- round((floor(f / 2000))/(flimd[2] - flimd[1]))
    wl <- wl * mag
    if (ovlp == 0) 
      ovlp <- 100
    ovlp <- 100 - round(ovlp/mag)
    flim <- flimd
  }
  n <- nrow(wave)
  step <- seq(1, n - wl, wl - (ovlp * wl/100))
  
  # to fix function name change in after version 2.0.5
  # if (exists("stdft")) stft <- stdft
  z <- stft_wrblr_int(wave = wave, f = f, wl = wl, zp = zp, step = step, 
            wn = wn, fftw = fftw, scale = norm, complex = complex)
  if (!is.null(tlim) && trel) {
    X <- seq(tlim[1], tlim[2], length.out = length(step))
  }  else {
    X <- seq(0, n/f, length.out = length(step))
  }
  if (is.null(flim)) {
    Y <- seq(0, (f/2) - (f/wl), length.out = nrow(z))/1000
  } else {
    fl1 <- flim[1] * nrow(z) * 2000/f
    fl2 <- flim[2] * nrow(z) * 2000/f
    z <- z[(fl1:fl2) + 1, ]
    Y <- seq(flim[1], flim[2], length.out = nrow(z))
  }
  if (!is.null(dB)) {
    if (is.null(dBref)) {
      z <- 20 * log10(z)
    } else {
      z <- 20 * log10(z/dBref)
    }
    if (dB != "max0") {
      if (dB == "A") 
        z <- dBweight(Y * 1000, dBref = z)$A
      if (dB == "B") 
        z <- dBweight(Y * 1000, dBref = z)$B
      if (dB == "C") 
        z <- dBweight(Y * 1000, dBref = z)$C
      if (dB == "D") 
        z <- dBweight(Y * 1000, dBref = z)$D
    }
  }
  Z <- t(z)
  
  maxz <- round(max(z, na.rm = TRUE))
  if (!is.null(dB)) {
    if (is.null(collevels)) 
      collevels <- seq(maxz - 30, maxz, by = 1)
    if (is.null(contlevels)) 
      contlevels <- seq(maxz - 30, maxz, by = 10)
  } else {
    if (is.null(collevels)) 
      collevels <- seq(0, maxz, length = 30)
    if (is.null(contlevels)) 
      contlevels <- seq(0, maxz, length = 3)
  }
  Zlim <- range(Z, finite = TRUE, na.rm = TRUE)
  
  if (!is.null(amp.cutoff)) Z[Z >= (diff(range(Z)) * amp.cutoff) + min(Z)] <- 0 
  
  if (!fast.spec)
    filled_contour_wrblr_int(x = X, y = Y, z = Z, bg.col = colbg, levels = collevels, 
                          nlevels = 20, plot.title = title(main = main, 
                                                           xlab = tlab, ylab = flab), color.palette = palette, 
                          axisX = FALSE, axisY = axisY, col.lab = collab, 
                          colaxis = colaxis, add = add) else {
                            image(x = X, y = Y, z = Z, col = palette(30), xlab = tlab, ylab = flab, axes = FALSE)
                            if (!is.null(sel.tab))    
                              out <- lapply(1:nrow(sel.tab), function(i)
                                image(x = X[X > sel.tab$start[i] & X < sel.tab$end[i]], y = Y[Y > sel.tab$bottom.freq[i] & Y < sel.tab$top.freq[i]], z = Z[X > sel.tab$start[i] & X < sel.tab$end[i], Y > sel.tab$bottom.freq[i] & Y < sel.tab$top.freq[i]], col = palette.2(30), xlab = tlab, ylab = flab, axes = FALSE, xlim = range(X), add = TRUE)      
                              )
                            
                            
                            if (axisY) axis(2, at = pretty(Y), labels = pretty(Y), cex.axis = cexlab)
                            if (bx)  box()
                            if (!is.null(main)) title(main)       
                        }
  
  if (axisX) {
    if (rm.zero)
      axis(1, at = pretty(X)[-1], labels = pretty(X)[-1], cex.axis = cexaxis)  else
        axis(1, at = pretty(X), labels = pretty(X), cex.axis = cexaxis) 
  }
  
  if (grid) 
    grid(nx = NA, ny = NULL, col = colgrid)
  
}
