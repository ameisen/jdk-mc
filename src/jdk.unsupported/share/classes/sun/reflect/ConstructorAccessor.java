package sun.reflect;

import java.lang.reflect.InvocationTargetException;

// Delegating wrapper class for jdk.internal.reflect.ConstructorAccessor
public final class ConstructorAccessor {
		private final jdk.internal.reflect.ConstructorAccessor delegate;

		public ConstructorAccessor(jdk.internal.reflect.ConstructorAccessor accessor) {
			delegate = accessor;
		}

    public Object newInstance(Object[] args)
        throws InstantiationException,
               IllegalArgumentException,
               InvocationTargetException {
			return delegate.newInstance(args);
		}
}
