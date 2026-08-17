import type { HTMLAttributes, PropsWithChildren } from 'react';

import { cn } from '../../lib/cn';

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        `
          card rounded-3xl border border-white/8 bg-white/4.5
          shadow-[0_20px_70px_rgb(0_0_0/0.16)]
        `,
        className,
      )}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        `
    p-5
    sm:p-6
  `,
        className,
      )}
      {...props}
    />
  );
}

export function CardTitle({ className, ...props }: HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h2
      className={cn('text-lg font-semibold tracking-tight text-white', className)}
      {...props}
    />
  );
}

export function CardDescription({
  className,
  ...props
}: HTMLAttributes<HTMLParagraphElement>) {
  return <p className={cn('mt-1 text-sm/6 text-slate-400', className)} {...props} />;
}

export function CardContent({
  className,
  ...props
}: PropsWithChildren<HTMLAttributes<HTMLDivElement>>) {
  return (
    <div
      className={cn(
        `
    px-5 pb-5
    sm:px-6 sm:pb-6
  `,
        className,
      )}
      {...props}
    />
  );
}
