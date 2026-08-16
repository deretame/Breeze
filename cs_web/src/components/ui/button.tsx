import type { ButtonHTMLAttributes, PropsWithChildren } from 'react';

import { cn } from '../../lib/cn';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> &
  PropsWithChildren<{
    variant?: ButtonVariant;
    size?: 'sm' | 'md' | 'lg';
  }>;

const variants: Record<ButtonVariant, string> = {
  primary:
    'bg-[var(--accent)] text-slate-950 shadow-[0_10px_24px_rgb(45_212_191/0.18)] hover:bg-teal-300',
  secondary:
    'border border-white/10 bg-white/[0.07] text-white hover:border-white/20 hover:bg-white/10',
  ghost: 'text-slate-300 hover:bg-white/[0.07] hover:text-white',
  danger: 'border border-rose-400/20 bg-rose-400/10 text-rose-200 hover:bg-rose-400/20',
};

const sizes = {
  sm: 'min-h-9 px-3 text-xs',
  md: 'min-h-11 px-4 text-sm',
  lg: 'min-h-13 px-5 text-base',
};

export function Button({
  className,
  variant = 'primary',
  size = 'md',
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center gap-2 rounded-xl font-semibold transition disabled:cursor-not-allowed disabled:opacity-50',
        variants[variant],
        sizes[size],
        className,
      )}
      {...props}
    >
      {children}
    </button>
  );
}
