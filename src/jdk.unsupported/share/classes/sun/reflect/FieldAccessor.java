package sun.reflect;

// Delegating wrapper class for jdk.internal.reflect.FieldAccessor
public final class FieldAccessor {
		private final jdk.internal.reflect.FieldAccessor delegate;

		public FieldAccessor(jdk.internal.reflect.FieldAccessor accessor) {
			delegate = accessor;
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public Object get(Object obj) throws IllegalArgumentException {
			return delegate.get(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public boolean getBoolean(Object obj) throws IllegalArgumentException {
			return delegate.getBoolean(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public byte getByte(Object obj) throws IllegalArgumentException {
			return delegate.getByte(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public char getChar(Object obj) throws IllegalArgumentException {
			return delegate.getChar(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public short getShort(Object obj) throws IllegalArgumentException {
			return delegate.getShort(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public int getInt(Object obj) throws IllegalArgumentException {
			return delegate.getInt(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public long getLong(Object obj) throws IllegalArgumentException {
			return delegate.getLong(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public float getFloat(Object obj) throws IllegalArgumentException {
			return delegate.getFloat(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public double getDouble(Object obj) throws IllegalArgumentException {
			return delegate.getDouble(obj);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void set(Object obj, Object value)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.set(obj, value);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setBoolean(Object obj, boolean z)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setBoolean(obj, z);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setByte(Object obj, byte b)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setByte(obj, b);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setChar(Object obj, char c)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setChar(obj, c);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setShort(Object obj, short s)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setShort(obj, s);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setInt(Object obj, int i)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setInt(obj, i);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setLong(Object obj, long l)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setLong(obj, l);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setFloat(Object obj, float f)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setFloat(obj, f);
		}

    /** Matches specification in {@link java.lang.reflect.Field} */
    public void setDouble(Object obj, double d)
        throws IllegalArgumentException, IllegalAccessException {
			delegate.setDouble(obj, d);
		}
}
