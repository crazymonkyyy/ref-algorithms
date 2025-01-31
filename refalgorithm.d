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
			if(r.empty){return typeof((){return r.front;}()).init;}
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
auto impurerange(){
	struct range{
		int i;
		auto front()=>i++;
		void popFront(){}
		bool empty()=>i>5;
	}
	return range();
}
mixin print!"impurerange/*intentally incorrect*/";
mixin print!"impurerange.filter1!(a=>true)";
auto cache(R)(R r){
	struct Cache{
		R r;
		typeof((){return r.front;}()) e;
		bool isnull=true;
		auto front(){
			if(isnull){
				e=r.front;
				isnull=false;
			}
			return e;
		}
		void popFront(){isnull=true;r.popFront;}
		bool empty(){
			if(isnull){
				e=r.front;
				isnull=false;
			}
			return r.empty;
		}
	}
	return Cache(r);
}
mixin print!"impurerange.cache.filter1!(a=>true)";
mixin print!"countdown(5).filter1!(a=>a>3).cache";
auto filter2(alias F,R)(R r)=>r.filter1!F.cache;
mixin print!"countdown(5).filter2!(a=>a>3)";
auto chain(R...)(R r){
	struct Chain{
		R r;
		auto front(){
			static foreach(I;0..r.length-1){
				if( ! r[I].empty){return r[I].front;}
			}
			return r[$-1].front;
		}
		void popFront(){
			static foreach(I;0..r.length-1){
				if( ! r[I].empty){r[I].popFront;return;}
			}
			r[$-1].popFront;
		}
		bool empty(){
			static foreach_reverse(I;0..r.length){
				if( ! r[I].empty) return false;
			}
			return true;
		}
	}
	return Chain(r);
}
mixin print!"chain(five,five.map!(a=>a*2),countdown(5))";
mixin print!"chain(five)";

auto indexby(A,R)(ref A array,R r){
	struct Indexby{
		A* a;
		R r;
		auto front()=>(*a)[r.front];
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return Indexby(&array,r);
}
auto indexby2(A,R)(A array,R r){
	struct Indexby{
		A a;
		R r;
		auto front()=>a[r.front];
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return Indexby(array,r);
}
string[] somearray=["foo","bar","foobar","hello","world"];
mixin print_!"somearray";
mixin print!"somearray.indexby(countdown(4))";
int[] somearray2=[4,2,3,1,0];
mixin print_!"somearray2";
mixin print!"somearray2.indexby(somearray2.indexby(count(0,4,1)))";
auto array(R)(R r){
	typeof((){return r.front;}())[] a;
	foreach(e;r){
		a~=e;
	}
	//while( ! r.empty){
	//	a~=r.front;
	//	r.popFront;
	//}
	return a;
}
mixin print_!"countdown(5).array";
auto array2(R)(R r){
	auto a=r.array;
	return a.indexby2(count(0,cast(int)a.length,1));
}
auto slide(R)(R r){
	struct Slide{
		R r;
		auto front()=>r;
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return Slide(r);
}
mixin print!"countdown(3).slide";
auto only(E)(E e){//only here for sort
	struct Only{
		E front;
		bool empty=false;
		void popFront(){empty=true;}
	}
	return Only(e);
}
//sorts shouldnt be pure in any real code
//typeof((){return R.init.front;}())[] sort(R)(R r)=>chain(
//	r.drop(1).filter2!(a=>a<r.front).array2.sort,
//	r.front.only,
//	r.drop(1).filter2!(a=>a>=r.front).array2.sort).array;
//mixin print!"countdown(10).sort";
// clever pure functional sort is hard to get working idk
