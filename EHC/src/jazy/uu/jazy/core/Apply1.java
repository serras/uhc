package uu.jazy.core ;

/**
 * Lazy and Functional.
 * Package for laziness and functions as known from functional languages.
 * Written by Atze Dijkstra, atze@cs.uu.nl
 */

/**
 * An application of a Eval to 1 parameter.
 */
class Apply1 extends Apply
{
	//private static Stat statNew = Stat.newNewStat( "Apply1" ) ;
	
	protected Object p1 ;
	
	public Apply1( Object f, Object p1 )
	{
		super( f ) ;
		this.p1 = p1 ;
		//statNew.nrEvents++ ;
	}
	
    protected void eraseRefs()
    {
    	//function = null ;
    	p1 = null ;
    }
    
    public Object[] getBoundParams()
    {
	    if ( p1 == null )
	        return Utils.zeroArray ;
	    return new Object[] {p1} ;
    }

    public int getNrBoundParams()
    {
        return 1 ;
    }

}
