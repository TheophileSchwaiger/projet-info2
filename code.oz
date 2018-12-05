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
      fun {Duration Time Partition}
	 D
	    %Calcule la duree de la partition
	 fun {HowLong Partition Acc}
	    case Partition of H|T then
	       case H of silence(duration:D) then
		  {HowLong T Acc+D}
	       [] note(name:N octave:O sharp:S duration:D instrument:I) then
		  {HowLong T Acc+D}
	       [] Head|Tail then
		  case Head of silence(duration:D) then
		     {HowLong T Acc+D}
		  [] note(name:N octave:O sharp:S duration:D instrument:I) then
		     {HowLong T Acc+D}
		  end
	       else
		  {HowLong T Acc}
	       end
	    else
	       Acc
	    end
	 end
      in
	 D = {HowLong Partition 0}
	 if D\= 0.0 then
	    {Stretch Time/D Partition}
	 else
	    nil
	 end
      end
%etire la partition d'un facteur Facteur
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
	    L = [c c#nil d d#nil e f f#nil g g#nil a a#nil b]%notes dans une octave
	 in
	    case Partition of H|T then
	       case H of silence(duration:D) then
		  silence(duration:D)|{Transpose N T} %si cest un silence rien ne change
	       [] note(name:Name octave:Octave sharp:S duration:D instrument:I) then
		  case{List.nth L {GetNote L Name 1}} of A#nil then
		     {NoteToExtended A#(Octave+{GetOctave L N {GetNote L Name 1}})}|{Transpose N T}
		  [] A then
		     {NoteToExtended {VirtualString.toAtom A#(Octave+{GetOctave L N {GetNote L Name 1}})}}|{Transpose N T}
		  end
		 %renvoie la version etendue de la note simplifiee donnee par la lettre dans la liste et loctave
	       [] Head|Tail then
		  {Transpose N H}|{Transpose N T}
	       end
	    end
	 end
      end
   in
      case Partition of H|T then
	 case H of note(name:Name octave:Octave sharp:S duration:D instrument:I) then
	    H|{PartitionToTimedList T}%si cest une note ou un silence on enchaine sans rien faire
	 [] silence(duration:D) then
	    H|{PartitionToTimedList T}
	 [] Head|tail then
	    {PartitionToTimedList H}|{PartitionToTimedList T}
	 [] duration(seconds:D Partition)then
	    {Append {Duration D Partition} {PartitionToTimedList T}}
	 [] stretch(factor:F Partition) then
	    {Append {Stretch F Partition} {PartitionToTimedList T}}
	 [] drone(note:NC amount:N) then
	    {Append {Drone NC N} {PartitionToTimedList T}}
	 [] transpose(semitones:I Partition) then
	    {Append {Transpose I Partition} {PartitionToTimedList T}}
	 [] Atom then
	    {NoteToExtended Atom}|{PartitionToTimedList T}%si ce nest pas une note etendue
	       
	 end
      end
   end

      
  
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music}
      fun{Reverse L Acc}
	    case L of nil then Acc
	    []H|T then {Reverse T H|Acc}
	    end
	 end

			%repete "A" foi la liste M
%retourn une liste dechantillons 
	 fun{Repeat A B}
	    if A==0 then nil
	    else {Append B {Repeat A-1 B}}
	    end
	 end

			%repete la list OldL de sorte d avoir une liste de "NbrElement" element. 
			%retourn une liste 
		%OldL et L doivent etre les meme
	 fun{Loop L1 L2 N}
	    case L2 of H|T andthen N\=0 then
	       H|{Loop L1 T N-1}
	    else
	       if N\=0 then
		  {Loop L1 L1 N}
	       else
		  nil
	       end
	    end
	 end

			%retourne les  elements de la liste entre Start et Finish-1
			%prend de Start compris a Finish noncompris

			%index commence a 0
		%Start et Finish sont des integer
	 fun{Cut S F N}
	    case N of H|T then 
	       if S==0 andthen F >0 then
		  H|{Cut S F-1 T}
	       elseif S==0 andthen F==0 then
		  nil
	       elseif S>0 then
		  {Cut S-1 F-1 T}
	       end
	    else
	       if S >0 then
		  {Cut 0 F-S nil}
	       elseif S==0 andthen F >0 then
		  0|{Cut S F-1 nil}
	       else
		  nil
	       end
	    end
	 end

			%retourne une liste d echantillons entre Low et High
			%les elements de la liste plus petit que low sont ramenes a low et ceux plus haut que hight sont ramene a high
		%Low et High sont des Float
	 fun{Clip Low High M}
	    case M of H|T then
	       if H>High then
		  High|{Clip Low High T}
	       elseif H<Low then
		  Low|{Clip Low High T}
	       else
		  H|{Clip Low High T}
	       end
	    else
	       nil
	    end
	 end


		
	 
      {Project.readFile 'wave/animals/cow.wav'}
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
