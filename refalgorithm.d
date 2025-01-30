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
mixin print_!"countdown(5).reduce1!((a,b)=>a+b)(0)";
