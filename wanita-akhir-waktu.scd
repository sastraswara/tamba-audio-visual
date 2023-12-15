(
s = Server.local;
s.options.numOutputBusChannels_(16);
s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
Window.closeAll;
MIDIClient.init;
"Server is set.".postln;

// Global Path Name
~path = PathName(thisProcess.nowExecutingPath).parentPath;


// Create a wavetable
~createWaveTable = {
	var wt_sig;

	wt_sig = 10.collect { |i|
		var numSegs = i.linexp(0, 9, 4, 40).round;

		Env(
			[0] ++ ({ 1.0.rand }.dup(numSegs-1) * [1, -1]).scramble ++ [0],
			{ exprand(1, i.linexp(0, 9, 1, 50)) }.dup(numSegs),
			{ [\sine, 0, exprand(1, 20) * [1, -1].choose].wchoose([9-1, 3, i].normalizeSum) }.dup(numSegs)
		).asSignal(1024);

	};

	~wt_buf = Buffer.allocConsecutive(10, s, 2048, 1, { |buf, index|
		buf.setnMsg(0, wt_sig[index].asWavetable);
	});
};

~createRebabTable = {
	var wt;
	wt = Array.fill(4, {
		var numSegs = rrand(4, 20);
		Env(
			levels: [0] ++
			(({ rrand(0, 1) })!(numSegs-1) * [1, -1]).scramble
			++ [0],
			times: { exprand(1, 20) }!numSegs,
			curve: { rrand(-20,20) }!numSegs
		).asSignal(1024).asWavetable;
	});
	~rebabBuf = Buffer.allocConsecutive(4, s, 2048);
	~rebabBuf.do({
		arg buf, i;
		buf.loadCollection(wt[i]);
	});
};


// Create laras
~loadLaras = {
	var path = [
		PathName("assets/rbipelogbem.scl"),
		PathName("assets/rbipelogbemsorog.scl")
	];

	~laras = Dictionary();

	path.do { |pth, i|
		var name = [
			\pelogBem,
			\pelogBemSorog,
		];
		var currentPath = ~path +/+ pth;
		var scl = Scala.open(currentPath.fullPath);
		~laras.add(name[i] -> scl.scale);
	};
};


// Gamelan samples as dictionary
~loadGamelanSamplesDict = {
	var samplePath;

	~gamelanDict = Dictionary();

	samplePath = ~path +/+ PathName("samples");

	samplePath.folders.do { | folder |
		var sampleSym = folder.folderName.asSymbol;

		var bufArray =	folder.files.collect { | file|
			if (file.extension == "wav"){
				Buffer.readChannel(s, file.fullPath, channels:[0]);
			};
		};

		~gamelanDict.add(sampleSym -> bufArray);
	};

	// Load vocal
	~samp = Buffer.readChannel(s, "/home/respati/Dropbox/2 - Project/01 Stockholm Residency/08 Konser Stockholm/02 Komposisi/assets/pangkur_yimma.wav", channels: 0);
};

// Clean up function
~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
	Window.closeAll;
};

// Function that aids composition
// ------------------------------

~musicFunc = {
	// Dictionary of functions
	f = Dictionary();

	// Add rebaban
	f.add(\addRebaban -> {
		arg soundBuf, rebabNum=1, ampMin=(-40), ampMax=(-30),
		durMin=2, durMax=4, susMin=2, susMax=4, scaleType=~laras[\pelogBem],
		degreeList=(-15..15);

		rebabNum.do({
			~rebabArr = ~rebabArr.add(
				Pbind(
					\instrument, \rebaban,
					\degree, Pwalk(
						list: degreeList,
						stepPattern: Prand([-1, 0, 1], inf),
						startPos: degreeList.size.rand,
						directionPattern: -1
					),
					\scale, scaleType,
					\amp, Plprand(ampMin, ampMax, inf).dbamp,
					\buf, soundBuf,
					\numBufs, 4,
					\dur, Pexprand(lo: durMin, hi: durMax, length: inf),
					\sustain, Pkey(\dur) * Pexprand(1.1, 1.5)
				).play;
			);
		});

		~rebabArr.size.postln;
	});

	// Add glissando rebab
	f.add(\addGlisRebab -> {
		arg soundBuf, degreeList=(-15..15), rebabNum=1, ampMin=(-40),
		ampMax=(-30), scaleType=~laras[\pelogBem],
		durMin=2, durMax=4, susMin=2, susMax=4, legato=2, lagMean=2, lagDev=1,
		relMin=4, relMax=8;

		rebabNum.do({
			~rebabArr = ~rebabArr.add(
				PmonoArtic(\rebaban,
					\degree, Pwalk(
						list: degreeList,
						stepPattern: Prand((-1..1), inf),
						startPos: degreeList.size.rand,
						directionPattern: -1
					),
					\amp, Plprand(ampMin, ampMax, inf).dbamp,
					\buf, soundBuf,
					\numBufs, 4,
					\scale, scaleType,
					\dur, Pexprand(lo: durMin, hi: durMax),
					\legato, legato,
					\lagtime, Pgauss(mean: lagMean, dev: lagDev),
					\rel, relMin.exprand(relMax),
					//\lagtime, Pgauss(mean: 3, dev: 1, length: inf)
				).play;
			);
		});
		~rebabArr.size.postln;
	});
};

// Composition of music materials
// ------------------------------

~compose = {
	// Dictionary of events
	e = Dictionary();

	// Rebab Walk
	e.add(\rebabWalk -> {
		var walkPattern = Pbrown(12, 17, 1).asStream;
		Pbind(
			\instrument, \vosc,
			\dur, Pexprand(4, 16),
			\atk, Pexprand(2, 6),
			\sus, 0,
			\rel, Pexprand(8, 16),
			\c0, Pexprand(1, 2),
			\c1, Pexprand(1, 2).neg,
			\detune, Pfunc({ rrand(0.15, 0.4) } ),
			\interfreq, 10.reciprocal,
			\buf, ~wt_buf[0],
			\freq, Pfunc({
				var deg = walkPattern.next.asInteger;
				var key;

				if (0.6.coin) {
					key = \pelogBem;
				} {
					key = \pelogBemSorog;
				};

				~laras[key].degreeToFreq(deg, 148.5, 0)
			}),
			\amp, Pexprand(0.2, 0.4),
			\pan, Pwhite(-1.0, 1.0),
			\out, 0, // 2
			//\rsend, -5
		).play(quant: 1);
	});

	// Rebab Cluster
	e.add(\rebabCluster -> {
		Pbind(
			\instrument, \vosc,
			\dur, Pwrand([1, 4, 6, 9, 12], [0.35, 0.25, 0.2, 0.15, 0.05], inf),
			\atk, Pexprand(3, 6),
			\sus, 0,
			\rel, Pexprand(5, 10),
			\c0, Pexprand(1, 2),
			\c1, Pexprand(1, 2).neg,
			\detune, Pfunc({ rrand(0.15, 0.4) }!3 ),
			\interfreq, 10.reciprocal,
			\buf, ~wt_buf[0],
			\freq, Pfunc({
				var key = \pelogBem;
				var degArr;
				if (0.4.coin){
					key = \pelogBemSorog;
				};
				degArr = (-10..20).collect { |deg|
					~laras[\pelogBem].degreeToFreq(deg, 148.5*2, 0);
				};
				degArr.scramble[0..rrand(2, 10)];
			}),
			\amp, Pexprand(0.05, 0.2)*1.25,//Pexprand(0.001, 0.01)* 2,
			\pan, Pwhite(-1.0, 1.0),
			\out, 2, // 2
		).play(quant: 1);
	});

	// Rebab with Gong Partials
	e.add(\rebabPartials -> {
		Pbind(
			\instrument, \vosc,
			\dur, Pwrand([1, 4, 6, 9, 12], [0.35, 0.25, 0.2, 0.15, 0.05], inf),
			\atk, Pexprand(3, 6),
			\sus, 0,
			\rel, Pexprand(5, 10),
			\c0, Pexprand(1, 2),
			\c1, Pexprand(1, 2).neg,
			\detune, Pfunc({ rrand(0.15, 0.4) }!3 ),
			\interfreq, 10.reciprocal,
			\buf, ~wt_buf[0],
			//\scale, ~laras[\pelogBem], //Scale.minorPentatonic,
			\freq, Pfunc({
				// Output Fluidbuf Sinefeatures
				var gongParts = [
					50.124778747559, 319.98275756836, 473.56112670898,
					656.83489990234, 864.19073486328, 1050.1136474609,
					1237.0729980469, 1428.0616455078, 1567.7589111328,
					1677.8873291016, 1781.8243408203, 1941.7581787109,
					2144.1215820312, 2282.5983886719, 2465.06640625
				];
				gongParts.scramble[0..rrand(1, 10)];
			}),
			\amp, Pexprand(0.05, 0.2),//Pexprand(0.001, 0.01)* 2,
			\pan, 0,//Pwhite(-1.0, 1.0),
			\out, 2, // 2
			//\rout, ~rbus,
			//\rsend, -5
		).play(quant: 1);
	});

	// Rebab Senggrengan 1-5
	e.add(\rebabSenggrengan -> {
		Pbind(
			\instrument, \vosc,
			\buf, ~wt_buf[0],
			\dur, 1,
			\freq, [148.5, 221.9], // 1-5
			\detune, Pwhite(0.03, 0.2),
			\atk, Pexprand(1, 4),
			\sus, Pexprand(0.1, 1),
			\rel, Pexprand(0.5, 2),
			\amp, Pgauss(0.1, 0.025),
			\out, 4 // 2
		).play(quant: 1);
	});

	// Rebab Drone
	e.add(\rebabDrone -> {
		Pbind(
			\instrument, \vosc,
			\buf, ~wt_buf[0],
			\dur, 1,
			\freq, 55.48,
			\detune, Pwhite(0.03, 0.2),
			\atk, 2,
			\sus, 0.1,
			\rel, 2,
			\amp, 0.15,
			\out, 4 // 2
		).play(quant: 1);
	});


	// Percussion playing
	//+++
	e.add(\stochasticRun -> {
		Routine {
			loop{
				var clusterSize = 5.rrand(15);
				var coin = 1.0.rand;
				var bufArray = ~gamelanDict[\SaronPelog];// ++ ~gamelanDict[\BonangBarungSlendro];

				clusterSize.do {
					Synth(\percussionPlayer, [
						\buf, bufArray.choose,
						\amp, 0.2.rrand(0.7),
						\rel, 2.exprand(4),
						\rate, [0.25, 0.5, 1, 2, 4].choose * (-0.1.rrand(0.1)).midiratio, // -1, 1
						\out, 6
					]);
				};

				if (coin < 0.95) {
					(0.1).wait;
				} {
					4.0.exprand(8.0).wait;
				};
			}
		}.play(quant: 1);
	});


	e.add(\stochasticBounce -> {
		var bounce = {
			var walkPattern = Pwalk(
				~gamelanDict[\SaronPelog],
				Prand((-6..6), inf),
				1,
				~gamelanDict[\SaronPelog].size.rand
			);

			var randPattern = Prand(~gamelanDict[\SaronPelog], inf);

			var bufPattern = [walkPattern, randPattern];

			Pbind(
				\instrument, \percussionPlayer,
				\buf, bufPattern.choose,
				\dur, Pgeom(1.rrand(2), 0.8, 10.rrand(20)),
				\rate, [0.125, 0.25, 0.5, 1, 2].choose * Pwhite(0.98, 1.02),
				\rel, 0.25.rrand(0.5),
				\pan, Pwhite(-1.0, 1.0),
				\amp, Pgauss(1, 0.1),
				\out, 8//2
			).play;
		};

		Routine {
			loop {
				bounce.value;
				0.75.exprand(4).wait;
			};
		}.play(quant: 1);
	});

	e.add(\layers -> {
		var samp = ~gamelanDict[\SaronPelog];
		var variation = [
			[samp[23]],
			[samp[23], samp[28]],
			[samp[13], samp[23], samp[28]],
			[samp[23], samp[28], samp[23]],
			[samp[23], samp[28], samp[23], samp[8]],
			[samp[28], samp[23], samp[13], samp[8]],
			[samp[13], samp[8]],
			[samp[13], samp[8], samp[3]]
		];
		var durArr = [4/3, 3/4, 5/4, 4/5, 5/7, 9/7, 7/6, 6/7, 8/7, 7/8, 9/8]*0.25;
		var durSeq = Pxrand(durArr, inf).asStream;

		var layer = { |pan|
			var seq = Pseq(variation, inf).asStream;
			var poisson = Pexprand(20, 60).asStream;
			var amp = Pgauss(0.5, 0.1).asStream;

			Routine {
				loop {
					var eventDur = poisson.next;
					var pat = seq.next;
					var acum = 0;
					var dur = durSeq.next;

					while({ acum < eventDur }, {
						pat.do { |note|
							Synth(\percussionPlayer, [
								\buf, note, \rate, 0.5,
								\rel, 0.7, \amp, amp.next, \pan, pan, \out, 10
							]);
							acum = acum + dur;
							dur.wait;
						};
					});
				};
			}.play(quant: 1);
		};

		[-1, -0.5, 0, 0.5, 1].collect { |pval| layer.value(pval) };
	});


	e.add(\sekar -> {
		var sekarPlayer;
		sekarPlayer = 5.collect{
			Pbind(
				\instrument, \playBuf,
				\buf, ~samp,
				\ratio, 1.27 * Prand([0.5, 1], inf),
				\win, 0.1,
				\dis, 0.5,
				\pos, Pbrown(0, 0.9),
				\atk, Pwhite(0.5, 1),
				\sus, Pexprand(0.125, 2),
				\amp, Pwhite(0.4, 0.6),
				\delta, Pexprand(0.125, 2),
				\out, 12
			).play(quant: 1);
		};

		// Return accu
		sekarPlayer;
	});


	// Manyar Clusters
	// ---------------

	// Single rebab
	e.add(\singleRebab -> {
		~rebabArr = Array.new(maxSize: 50);
		f[\addRebaban].value(~rebabBuf, rebabNum: 1, scaleType: ~laras[\pelogBem]);
	});

	// Add rebab cluster
	e.add(\addRebab -> {
		f[\addRebaban].value(
			~rebabBuf,
			rebabNum: (2..8).choose,
			scaleType: [~laras[\pelogBem], ~laras[\pelogBemSorog]].choose
		);
	});

	// Add glissando cluster
	e.add(\addGliss -> {
		f[\addGlisRebab].value(
			~rebabBuf,
			rebabNum: (2..8).choose,
			scaleType: [~laras[\pelogBem], ~laras[\pelogBemSorog]].choose
		);
	});

	e.add(\rebabOff -> {
		Routine({
			var arrsize = ~rebabArr.size;
			for(0, arrsize-1) {
				arg i;
				~rebabArr.at(i).stop;
				exprand(0.5, 2).wait;
			};
			"All patterns are stopped.".postln;
		}).play;
		//~rebabArr.do(_.stop);
	});
};

// Midi controller definition
// --------------------------
~midiDefinition = {
	var player;
	var isActive;
	var patternSymbols;


	//MIDIIn.connectAll;

	// Dictionary of isActives
	isActive = Dictionary();

	patternSymbols = e.keys;

	// Initialize isActives values
	patternSymbols.do { |sym| isActive.put(sym, false) };

	// Dictionary of player
	player = Dictionary();
	patternSymbols.do { |sym| player.put(sym, nil) };

	MIDIdef.cc(\eventControl, { | val, num, chan, src |
		var sym, seg, toggle, turnoff;
		var oneChord, bpfOneShot;
		var oneShot;

		// Funtion to toggle and play the corresponding event
		toggle = { | sym |
			var currentPlayer = player[sym];
			if(isActive[sym]) {
				// check for size of the player
				if (currentPlayer.size==0) {
					currentPlayer.stop;
				}{
					currentPlayer.do(_.stop);
				};
				isActive[sym] = false;
				(sym.asString + "off.").postln;
			} {
				player.put(sym, e[sym].value);
				isActive[sym] = true;
				(sym.asString + "on.").postln;
			};
		};

		// Function to play one shots
		oneShot = { |val, sym|
			if (val==127) {
				e[sym].value;
				sym.asString.postln;
			};
		};

		// MIDI CC num mapping
		switch(num)
		// Rebab cluster 1
		{ 1 }{ toggle.(\rebabWalk); }
		{ 2 }{ toggle.(\rebabCluster); }
		{ 3 }{ toggle.(\rebabPartials); }
		{ 9 }{ toggle.(\rebabSenggrengan); }
		{ 10 }{ toggle.(\rebabDrone); }
		/*
		{ 5 }{ f[\updateDensity].value(val) }
		{ 6 }{ f[\updateRange].value(val) }
		{ 7 }{ f[\updateProbability].value(val, \ampA) }
		{ 8 }{ f[\updateProbability].value(val, \ampB) }
		*/

		// Rebab cluster 2 (Manyar)
		//{ 9  }{ e[\singleRebab].value; }
		//{ 10 }{ e[\addRebab].value; }
		//{ 11 }{ e[\addGliss].value; }
		//{ 12 }{ e[\rebabOff].value; }
		//{ 13 }{ toggle.(\rebabDrone); }

		//3.1 Cengkok patterns
		{ 17 }{ toggle.(\stochasticRun); }
		{ 18 }{ toggle.(\stochasticBounce); }
		{ 19 }{ toggle.(\layers); }
		//{ 20 }{ toggle.(\cengkok3); }

		// 4 Stochastic
		{ 25 }{ toggle.(\sekar); }
		//{ 26 }{ toggle.(\stochasticBounce); }
		//+++


		// 5 Gend
		//{ 33 } { toggle.(\peking); }
		//{ 34 } { toggle.(\kethuk); }
		//{ 35 } { toggle.value(\gong) }
		/*
		{ 33 }{ e[\singleRebab].value; }
		{ 34 }{ e[\addRebab].value; }
		{ 35 }{ e[\addGliss].value; }
		{ 36 }{ e[\rebabOff].value; }
		*/
		/*
		// 6
		{ 41 } { toggle.value(\sinCA) }
		{ 42 } { toggle.value(\sinAppergio) }

		// 7
		{ 49 }{ toggle.value(\wtChord) }
		{ 50 }{ toggle.value(\wtDrone) }

		// 8
		{ 57 }{ toggle.value(\bpfGlocke) }
		{ 58 }{ toggle.value(\bambooVibra2) }
		{ 59 }{ toggle.value(\bellCloud3) }
		{ 60 }{ oneShot.value(val, \bambooOneShot) }
		*/

		{ "Not implemented".postln; };

	}, chan: 2);

	"Midi definition is done".postln;
};

ServerBoot.add(~createWaveTable);
ServerBoot.add(~createRebabTable);
ServerBoot.add(~loadGamelanSamplesDict);
ServerBoot.add(~loadLaras);
ServerQuit.add(~cleanup);


// Server Boot
// ===========
s.waitForBoot({
	// Rebab wavetable
	SynthDef(\vosc, {
		var env = Env(
			[0, 1, 1, 0],
			[\atk.kr(0.01), \sus.kr(1), \rel.kr(0.01)],
			[\c0.kr(1), 0, \c1.kr(-1)]
		).kr(\done.kr(2));

		var detuneCtrl = LFNoise1.kr(0.1!8).bipolar(\detune.kr(0.2)).midiratio;
		var bufpos = \buf.kr(0) + LFNoise1.kr(\interfreq.kr(0.1)!8).range(0, 9);

		var sig = VOsc.ar(bufpos, \freq.kr(200)*detuneCtrl, { Rand(0, 2pi) }!8 );
		sig = Splay.ar(sig);
		sig = LeakDC.ar(sig);
		sig = Balance2.ar(sig[0], sig[1], \pan.kr(0), \amp.kr(0.2));
		sig = sig * env;

		Out.ar(\out.kr(0), sig);
		//Out.ar(\rout.kr(0), sig * \rsend.kr(-20).dbamp);
	}).add;


	// Percussion player
	SynthDef(\percussionPlayer, {
		var phs = Phasor.ar(
			0,
			BufRateScale.kr(\buf.kr) * \rate.kr(1),
			\start.kr(0) * BufFrames.kr(\buf.kr),
			\end.kr(1) * BufFrames.kr(\buf.kr)
		);
		var sig = BufRd.ar(
			1,
			\buf.kr,
			phs
		);
		var env = Env.perc(\atk.kr(0.01), \rel.kr(1)).kr(2);
		sig = sig * env * \amp.kr(1);
		sig = Pan2.ar(sig, \pan.kr(0));
		Out.ar(\out.kr(0), sig);
	}).add;


	// Sample Player
	SynthDef(\playBuf, {
		var sig = PlayBuf.ar(1, \buf.kr, BufRateScale.kr(\buf.kr), startPos: BufFrames.kr(\buf.kr)*\pos.kr(0), loop: 1);
		var env = Env.linen(\atk.kr(0.01), \sus.kr(1), 0.1).kr(2);
		sig = PitchShift.ar(sig, \win.kr(0.2), pitchRatio: \ratio.kr(1), timeDispersion: \dis.kr(0));
		sig = sig * env * \amp.kr(1);
		sig = Pan2.ar(sig, \pan.kr(0));
		Out.ar(\out.kr(0), sig);
	}).add;


	// Rebaban wave table
	SynthDef.new(\rebaban, {
		arg out=0, buf=0, numBufs=2, freq=300, sus=1,
		amp=0.2, atk=1, rel=3, gate=1, lagtime=0, curvelag=(-4),
		fc=1000, fx=0, fxamp=(-10);
		var sig, bufpos, detuneSig, env;
		// Wavetables
		detuneSig = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
		bufpos = buf + LFNoise1.kr(0.5).range(0, numBufs-1);
		sig = VOsc.ar(
			bufpos: bufpos,
			freq: freq.varlag(lagtime, curvelag) * detuneSig;
		);
		// Filter
		sig = LPF.ar(
			in: sig,
			freq: LFNoise2.kr(0.1).range(fc, fc*4);
		);
		//Envelopes
		env = EnvGen.kr(
			Env.asr(
				attackTime: atk,
				sustainLevel: 1,
				releaseTime: rel,
				curve: -4
			),
			gate,
			doneAction: 2
		);
		// Output signal
		sig = Splay.ar(sig);
		sig = LeakDC.ar(sig) * env * amp;
		Out.ar(out, sig);
	}).add;

	"SynthDefs are loaded.".postln;

	ServerTree.add(~compose);
	ServerTree.add(~midiDefinition);

	s.sync;
	s.freeAll;
	s.sync;

	"Preparation is done!".postln;
});
)


// SKETCHES
// Komposisi