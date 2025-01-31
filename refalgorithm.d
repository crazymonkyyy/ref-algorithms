auto countdown(int i){
	struct Countdown{
		int front;
		void popFront(){front--;}
		bool empty()=>front<=-1;
	}
	return Countdown(i);
}
mixin template print(string s){unittest{
	import std.stdio;
	s.write;
	"=>".write;
	mixin("auto foo="~s~";");
	while( ! foo.empty){
		foo.front.write(',');
		foo.popFront;
	}
	writeln;
}}
mixin template print_(string s){unittest{
	import std.stdio;
	s.write;
	"=>".write;
	mixin(s~".writeln;");
}}
mixin print!"countdown(5)";

auto map(alias F,R)(R r){
	struct Map{
		R r;
		auto front()=>F(r.front);
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return Map(r);
}
mixin print!"countdown(5).map!(a=>a*2)";
//eager filter, doesnt say its empty correctly
auto filter1(alias F,R)(R r){
	struct Filter{
		R r;
		auto front(){
			loop:
			if(r.empty){return typeof(r.front).init;}
			if(F(r.front)){return r.front;}
			r.popFront;
			goto loop;
		}
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return Filter(r);
}
mixin print!"countdown(5).filter1!(a=>a>3)/*incorrect*/";

//lazy reduce, lacks flexiblity in types and predictably does an extra operation; but god is it easier to implimet 
auto reduce1(alias F,R,E)(R r,E e){
	while( ! r.empty){
		e=F(r.front,e);
		r.popFront;
	}
	return e;
}
auto reduce2(alias F,R,E)(R r,E e)=>acc1!F(r,e).last;
mixin print_!"countdown(5).reduce1!((a,b)=>a+b)(0)";
mixin print_!"countdown(5).reduce2!((a,b)=>a+b)(0)";

//lazy acc, simliar problems as lazy reduce
auto acc1(alias F,R,E)(R r,E e){
	struct Acc{
		R r;
		E e;
		auto front()=>F(r.front,e);
		void popFront(){e=F(r.front,e);r.popFront;}
		bool empty()=>r.empty;
	}
	return Acc(r,e);
}
//todo impliment acc with reduce
mixin print!"countdown(5).acc1!((a,b)=>a+b)(0)";
auto last(R)(R r){
	auto e=r.front;
	while( ! r.empty){
		e=r.front;
		r.popFront;
	}
	return e;
}
mixin print_!"countdown(5).acc1!((a,b)=>a+b)(0).last";
auto count(int start,int end,int step){
	struct Count{
		int front;
		int end;
		int step;
		void popFront(){front+=step;}
		bool empty()=>step>0?front>end:front<end;
	}
	return Count(start,end,step);
}
mixin print!"count(3,6,1)";
mixin print!"count(3,9,3)";
mixin print!"count(9,3,-1)";
auto countdown2(int i)=>count(i,0,-1);
mixin print!"countdown2(6)";

auto cycle(R)(R r){
	struct Cycle{
		R r;
		R r2;
		auto front()=>r.front;
		void popFront(){r.popFront;if(r.empty)r=r2;}
		enum empty=false;
	}
	return Cycle(r,r);
}
auto take(R)(R r,int i){
	struct Take{
		R r;
		int i;
		auto front()=>r.front;
		void popFront(){r.popFront; i--;}
		bool empty()=>r.empty||i<=0;
	}
	return Take(r,i);
}
mixin print!"count(1,5,1).cycle.take(8)";
auto drop(R)(R r,int i){
	while(i-->0 && ! r.empty){
		r.popFront;
	}
	return r;
}
auto five()=>count(1,5,1);
mixin print!"five";
mixin print!"five.drop(2)";
mixin print!"five.drop(500)";
auto chunks(R)(R r,int i){
	struct Chunks{
		R r;
		int i;
		auto front()=>r.take(i);
		void popFront(){r=r.drop(i);}
		bool empty()=>r.empty;
	}
	return Chunks(r,i);
}
mixin print!"count(1,10,1).chunks(3)";


