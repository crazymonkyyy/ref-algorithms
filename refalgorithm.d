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
auto takeexact(R)(R r,int i){
	struct Take{
		R r;
		int i;
		auto front()=>r.front;
		void popFront(){r.popFront; i--;}
		bool empty()=>i<=0;
	}
	return Take(r,i);
}
mixin print!"count(1,5,1).cycle.take(8)";
mixin print!"count(1,5,1).takeexact(8)";
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
// clever pure functional sort is hard to get working idk, skiping

auto find(alias F,R)(R r){
	while( ! r.empty && ! F(r) ){
		r.popFront;
	}
	return r;
}
mixin print!"five.find!(a=>a.front==3)";
mixin print!"five.find!(a=>a.front==99)";
auto findnext(alias F,R)(R r){
	if(r.empty){return r;}
	r.popFront;
	return r.find!F;
}
mixin print!"five.find!(a=>a.front>=3).findnext!(a=>a.front>=3)";
mixin print!"five.find!(a=>a.front>=99).findnext!(a=>a.front>=99)";

auto overflow(R,E)(R r,E e){
	struct Overflow{
		R r;
		E e;
		auto front()=>r.empty?e:r.front;
		auto popFront(){
			if( ! r.empty){ r.popFront;}
		}
		auto empty()=>r.empty;
	}
	return Overflow(r,e);
}
auto baddrop20(R)(R r){
	foreach(i;0..20){r.popFront;}
	return r;
}
mixin print_!"five.baddrop20.front";
mixin print_!"five.overflow(-1).baddrop20.front";

struct Tuple(T...){
	T expand; alias expand this;
}
auto tuple(T...)(T t)=>Tuple!T(t);
mixin print_!"tuple(1,13.37)";

//auto zip(R...)(R r){
//	struct Zip{
//		R r;
//		auto front(){
//			enum args=count(0,r.length-1,1).map!(a=>"r["~cast(char)(a+'0')~"],");
//			return args;
//		}
//	}
//	return Zip(r);
//}
//mixin print_!"zip(five,five).front";
auto emptyrange(E)(E e){
	struct empty{
		E front;//void front(){} doesnt seem to work
		void popFront(){}
		enum bool empty=true;
	}
	return empty(e);
}
mixin print!"emptyrange(int.max)";
auto repeat(E)(E e,int i)=>emptyrange(e).takeexact(i);
mixin print!"5.repeat(3)";

auto replacewhen(alias F,alias G,R)(R r){
	struct replace{
		R r;
		auto front()=>F(r)?G(r):r.front;
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return replace(r);
}
mixin print!"five.replacewhen!(a=>a.front==3,a=>99)";
mixin print!"five.replacewhen!(a=>a.front%2,a=>a.drop(1).front)";

auto isdone(R)(R r){
	struct doneness{
		R r;
		auto front()=>r.empty;
		void popFront(){r.front;r.popFront;}
		auto empty()=>r.empty;
	}
	return doneness(r);
}
mixin print_!"int i;five.map!((a){i+=a; i.write(\",\");}).isdone.last";

auto mask(R,R2)(R r,R2 r2){
	struct Mask{
		R r; R2 r2;
		auto front()=>r.front;
		auto popFront(){
			r.popFront; r2.popFront;
			while( ! empty && ! r2.front){
				r.popFront; r2.popFront;
		}}
		auto empty()=>r.empty || r2.empty;
	}
	return Mask(r,r2).find!(a=>a.r2.front);
}
mixin print!"five.mask(countdown(10).map!(a=>a%2))/*needs testing*/";

auto takeuntil(R)(R base,R other){
	struct until{
		R r;
		R other;
		auto front()=>r.front;
		void popFront(){r.popFront;}
		bool empty()=>r==other;
	}
	return until(base,other);
}
mixin print!"five.takeuntil(five.find!(a=>a.front==3))";
//should work with sumtypes
template switchmap(alias F,Fs...){ auto switchmap(R)(R r){
	struct switch_{
		R r;
		auto front(){
			switch(F(r)){
				static foreach(i,f;Fs){
					case i:return f(r.front);
				}
				default: assert(0);
			}
		}
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
	}
	return switch_(r);
}}
mixin print_!"five.switchmap!(a=>a.front%2,a=>\"odd\".writeln,a=>a.writeln).isdone.last";
mixin print!"five.switchmap!(a=>a.front%2,a=>\"odd\",a=>\"even\")";
