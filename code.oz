local
   % See project statement for API details.
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Translate a note to the extended notation.
   fun {NoteToExtended Note}
      case Note
      of Name#Octave then
         note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then
         case {AtomToString Atom}
         of [_] then
            note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
         [] [N O] then
            note(name:{StringToAtom [N]}
                 octave:{StringToInt [O]}
                 sharp:false
                 duration:1.0
                 instrument: none)
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   fun {PartitionToTimedList Partition}
%Modifie la duree
      declare
      fun {Duration Time Partition}
	 local
	    A = {NewCell 0.0}
	    D
	 in
	    local
	    %Calcule la duree de la partition
	       fun {HowLong Partition}
		  case Partition of H|T then
		     case H of silence(duration:D) then
			A := @A+D
			{HowLong T}
		     [] note(name:N octave:O sharp:S duration:D instrument:I) then
			A := @A+D
			{HowLong T}
		     [] Head|Tail then
			case Head of silence(duration:D) then
			   A:= @A+D
			   {HowLong T}
			[] note(name:N octave:O sharp:S duration:D instrument:I) then
			   A:=@A+D
			   {HowLong T}
			end
		     end
		     @A
		  end
	       end
	    in
	       D = {HowLong Partition}
	       if D\= 0.0 then
		  {Stretch Time/D Partition}
	       else
		  nil
	       end
	    end
	 end
      end
%etire la partion d'un facteur Facteur
      declare
      fun {Stretch Facteur Partition}
	 case Partition of H|T then
	    case H of silence(duration:D) then
	       silence(duration:D*Facteur)|{Stretch Facteur T}%on redefinit la longueur duration
	    [] note(name:N octave:O sharp:S duration:D instrument:I) then
	       note(name:N octave:O sharp:S duration:D*Facteur instrument:I)|{Stretch Facteur T}
	    [] Head|Tail then
	       {Stretch Facteur H}|{Stretch Facteur T}%la liste de notes devient une partition a laquelle on applique stretch
	    end
	 else
	    nil
	 end
      end
   
%repete une note ou un accord amount fois
      fun{Drone Note Amount}
	 local N = {NewCell Note}
	 in
	    for I in 0..Amount-1 do
	       N:= @N|Note
	    end
	    @N|nil
	 end
      end
      fun{Transpose N Partition}%augmente chaque note de la partion de N demi-tons
	 local
	    fun{GetNote List Elem Acc}%renvoie la position de lelement dans la liste a partir de acc
	       case List of H|T then
		  if H\=Elem then
		     {GetNote T Elem Acc+1}
		  else
		     Acc
		  end
	       else
		  ~1
	       end
	    end
	    fun{GetOctave List N1 Elem1}%permet de calculer le nombre d octaves montees ou descendues en fonction des N1 demi-tons apd la position elem1
	       local
		  I = {NewCell 0}
	       in
		  if N1>0 then
		     for while:(N1>({List.length List}+1-Elem1+12*I)) do %on parcourt les octaves jusqua ce que on depasse les nombre de demi-tons montes
			I:=@I+1
		     end
		  else
		     for while: N1 =< (~Elem1-12*I) do %on parcourt dans lautre sens si le nombre de demi-tons est negatif
			I:=@I-1
		     end
		  end
		  @I
	       end
	    end
	    L = [c c# d d# e f f# g g# a a# b]%notes dans une octave
	 in
	    case Partition of H|T then
	       case H of silence(duration:D) then
		  silence(duration:D)|{Transpose N T} %si cest un silence rien ne change
	       [] note(name:Name octave:Octave sharp:S duration:D instrument:I) then
		  {NoteToExtended {List.nth L {GetNote L Name 1}+N}+Octave+{GetOctave L N {GetNote L Name 1}}}|{Transpose N T}%renvoie la version etendue de la note simplifiee donnee par la lettre dans la liste et loctave
	       [] Head|Tail then
		  {Transpose H}|{Transpose T}
	       end
	    end
	 end
      end
   in
      case Partition of H|T then
	 case H of note(name:Name octave:Octave sharp:S duration:D instrument:I) then
	    H|{PartitionToTimedList T}
	 [] silence(duration:D) then
	    H|{PartitionToTimedList T}
	 [] Head|tail then
	    {PartitionToTimedList H}|{PartitionToTimedList T}
	 [] duration(seconds:duration)then
	    {Duration duration Partition}
	 [] stretch(factor:factor) then
	    {Stretch factor Partition}
	 [] drone(note:noteorchord amount:natural) then
	    {Drone noteorchord natural}
	 [] transpose(semitones:integer) then
	    {Transpose integer Partition}
	 end
      end
   end

      
  
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music}
      % TODO
      {Project.readFile 'wave/animaux/cow.wav'}
   end






   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load 'joy.dj.oz'}
   Start

   % Uncomment next line to insert your tests.
   % \insert 'tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}

   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}

   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   {ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to `out.wav`.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end
