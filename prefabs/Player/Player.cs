using Godot;
using System;

namespace PoopyTheGame.Player;

public partial class Player : CharacterBody2D
{
    private static readonly float QuarterRotation = float.DegreesToRadians(90);
    
    [ExportGroup("Physics Properties")]
    [Export] public double Gravity { get; set; } = 100;
    [Export] public double Acceleration { get; set; } = 10;
    [Export] public double Deceleration { get; set; } = 10;
    [Export(PropertyHint.Range, "0,1")] public double FrictionPercent { get; set; } = 0.2;

    private double _speed;
    
    public override void _PhysicsProcess(double delta)
    {
        if (Input.IsActionPressed("left"))
        {
            _speed -= Acceleration * delta;
        }
        else if (Input.IsActionPressed("right"))
        {
            _speed += Acceleration * delta;
        }
        else
        {
            if (_speed > 0)
            {
                _speed -= Deceleration * delta;
            }
            else if (_speed < 0)
            {
                _speed += Deceleration * delta;
            }
        }

        var baseVector = Vector2.Right * (float)_speed;
        Velocity = baseVector with { Y = (float)(Gravity * delta) };
        MoveAndSlide();
        var collision = GetLastSlideCollision();
        if (collision is not null)
            Rotation = -collision.GetAngle();
    }
}
