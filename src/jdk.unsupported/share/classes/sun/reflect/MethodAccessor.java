package sun.reflect;

import java.lang.reflect.InvocationTargetException;

// Delegating wrapper class for jdk.internal.reflect.MethodAccessor
public final class MethodAccessor {
		private final jdk.internal.reflect.MethodAccessor delegate;

		public MethodAccessor(jdk.internal.reflect.MethodAccessor accessor) {
			delegate = accessor;
		}

    /** Matches specification in {@link java.lang.reflect.Method} */
    public Object invoke(Object obj, Object[] args)
        throws IllegalArgumentException, InvocationTargetException {
			return delegate.invoke(obj, args);
		}
}
