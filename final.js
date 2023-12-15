hush()

//
a.setBins(3)
//a.show()

// 1.1
shape(3)
  .scale([0.25, 0.5, 1, 2].fast(0.1).smooth())
  //.modulateRotate(osc(100), 6)
  //.modulate(noise(500))
  .modulateRotate(osc(100), ()=>a.fft[2]*6)
  .modulate(noise(500), ()=>0.2*a.fft[0]+0.1)
  .rotate(10, 0.05)
  .color(131/255, 56/255, 236/255)
  //.colorama(-4)
  .colorama([0.01, 0.05, 0.15, 0.2].fast(0.1).smooth())
  .contrast(1.6)
  .out(o0)
render(o0)


// 1.2
s0.initImage("file:///home/respati/Dropbox/2 - Project/01 Stockholm Residency/08 Konser Stockholm/03 Visual/18.jpg")
src(s0)
  .scale([1, 2, 4].fast(0.2).smooth())
  //.thresh(0.5)
  .thresh(0.5)
  .invert()
  .color(131/255, 56/255, 236/255)
  //.modulate(voronoi(10, 0.1, 1))
  .modulate(voronoi(10, 0.1, ()=>a.fft[2]*2))
  .rotate(10, [-0.02, 0.02].fast(0.1))
  .mult(noise(500, 0.5))
  .blend(o0, ()=> Math.sin(time/5))
  //.blend(o0, [0.9, 0.5, 0.2].fast(0.1).smooth())
  .out(o1)
render(o1)


// 2.1
s0.initImage("file:///home/respati/Dropbox/2 - Project/01 Stockholm Residency/08 Konser Stockholm/03 Visual/18.jpg")
src(s0)
  .scale([0.5, 1, 2, 4].fast(0.05).smooth())
  .thresh(0.3)
  .invert()
  .color(105/255, 48/255, 200/255)
  .modulate(voronoi(10, 0.1, 1))
  .modulateScale(src(o0), [1, 5, 10].fast(0.1))
  .rotate(10, [-0.02, 0.02].fast(0.1))
  .colorama([0.01, 0.05, 0.1].fast(0.1).smooth())
  .out(o0)
render(o0)


// 2.2
s0.initImage("file:///home/respati/Dropbox/2 - Project/01 Stockholm Residency/08 Konser Stockholm/03 Visual/12.jpg")
src(s0)
  .thresh(0.5)
  .invert()
  .rotate(1, 0.01)
  .modulate(voronoi(5,0.1,1.5))
  .color(255/255, 50/255,100/255)
  .contrast(3)
  .mult(voronoi(100,5,0.1))
  .modulateRotate(src(o0),[0.01, 0.05, 0.1].smooth())
  .blend(src(o0), [0.1, 0.5, 1].smooth().fast(0.1))
//.invert()
  //.modulateScale(src(s0), 10, 1)
  //.luma(0.01)
  //.add(noise())
  .out(o1)
render(o1)


// 3.1
shape(3)
  .scale([0.25, 0.5, 1, 2].fast(0.1).smooth())
  .modulateRotate(osc(100), 6)
  .modulate(noise(500))
  .rotate(10, 0.05)
  .color(251/255, 86/255, 7/255)
  .modulate(src(o0), ()=> Math.sin(time/10 * 0.01) * 0.3)
  //.colorama(-4)
  //.colorama([0.01, 0.05, 0.15, 0.2].fast(0.1).smooth())
  //.contrast(1.6)
  .out(o1)
render(o1)


// 3.2
osc(20, 0.01, 1.1)
  .kaleid(40) // 100
  .color(251/255, 86/255, 7/255)
  .modulate(src(o0), ()=> Math.sin(time/10) + 0.2)
  .modulate(src(o0).pixelate(5, 5).rotate(-10, 0.2), ()=> Math.sin(time/10 + 2)*0.01)
  .scale([0.6, 1, 0.8, 1 , 0.9, 1.1].fast(0.1).ease().smooth())
  .out(o0)
render(o0)


// 3.3
shape(3)
  .scale([0.25, 0.5, 1, 2].fast(0.1).smooth())
  //.modulateRotate(osc(100), 6)
  //.modulate(noise(500))
  .modulateRotate(osc(100), ()=>a.fft[2]*6)
  .modulate(noise(500), ()=>0.2*a.fft[0]+0.1)
  .rotate(10, 0.05)
  .color(251/255, 86/255, 7/255)
  //.colorama(-4)
  //.colorama([0.01, 0.05, 0.15, 0.2].fast(0.1).smooth())
  .contrast(1.6)
  .out(o0)
render(o0)

// end
hush()
